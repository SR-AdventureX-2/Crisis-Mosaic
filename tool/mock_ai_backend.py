"""Development-only multimodal conflict analysis API for the Flutter demo.

This server mirrors the production contract without calling a paid model. Replace
it with the real backend and start Flutter with CRISIS_MOSAIC_API_BASE_URL set to
that backend origin.
"""

from __future__ import annotations

import json
import os
import re
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


HOST = "127.0.0.1"
PORT = int(os.environ.get("CRISIS_MOSAIC_MOCK_AI_PORT", "52125"))
CONFLICT_PATH = re.compile(r"^/api/v1/conflicts/([^/]+)/ai-analysis$")


class Handler(BaseHTTPRequestHandler):
    server_version = "CrisisMosaicMockAI/1.0"

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/health":
            self._write_json(200, {"status": "ok", "service": "mock-ai-backend"})
            return
        self._write_json(404, {"error": {"code": "NOT_FOUND"}})

    def do_POST(self) -> None:  # noqa: N802
        match = CONFLICT_PATH.match(self.path)
        if not match:
            self._write_json(404, {"error": {"code": "NOT_FOUND"}})
            return
        try:
            content_length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(content_length) or b"{}")
            context = payload.get("context") or {}
            evidence = context.get("evidence") or []
            if not isinstance(evidence, list) or not evidence:
                self._write_json(
                    422,
                    {
                        "error": {
                            "code": "MISSING_EVIDENCE",
                            "message": "至少需要一条冲突证据",
                        }
                    },
                )
                return
            time.sleep(0.75)
            result = _analyze(match.group(1), evidence)
            self._write_json(200, {"data": result})
        except (ValueError, json.JSONDecodeError) as error:
            self._write_json(
                400,
                {"error": {"code": "INVALID_JSON", "message": str(error)}},
            )

    def log_message(self, format: str, *args: Any) -> None:
        print(f"[{self.log_date_time_string()}] {format % args}", flush=True)

    def _write_json(self, status: int, body: dict[str, Any]) -> None:
        content = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self._send_cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def _send_cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header(
            "Access-Control-Allow-Headers", "Authorization, Content-Type, Accept"
        )


def _analyze(conflict_id: str, evidence: list[dict[str, Any]]) -> dict[str, Any]:
    image_count = sum(item.get("modality") == "image" for item in evidence)
    text_count = len(evidence) - image_count
    assessments = [_assess(item) for item in evidence]
    recommended = max(assessments, key=lambda item: item["credibility_score"])
    return {
        "analysis_id": f"mock-api-{conflict_id}-{int(time.time())}",
        "suggested_conclusion": "沿江路东段已被积水覆盖，机动车当前不可通行",
        "reasoning_summary": (
            "API 已读取全部文字、图片元数据、OCR 和视觉特征，并按观察时间构建上下文。"
            "14:24 后的四条证据相互印证；14:00 的上报更可能已经过时，而非恶意虚假。"
        ),
        "confidence": 0.88,
        "recommended_evidence_id": recommended["evidence_id"],
        "context_summary": {
            "image_count": image_count,
            "text_count": text_count,
            "digest": "图片读取 → OCR/视觉提取 → 文字归一化 → 时间线对齐 → 多来源交叉验证",
        },
        "evidence_assessments": assessments,
        "warnings": [
            "真实性评分表示文件和来源未见明显篡改，不代表信息仍然具有时效性。",
            "AI 结果只用于辅助研判，最终结论必须由指挥人员确认。",
        ],
        "engine_label": "本地演示 API",
        "model_version": "multimodal-conflict-api-demo-v1",
        "data_as_of": "14:29",
    }


def _assess(item: dict[str, Any]) -> dict[str, Any]:
    evidence_id = str(item.get("id") or "unknown")
    observed_at = str(item.get("observed_at") or "")
    modality = item.get("modality")
    statement = str(item.get("statement") or "")
    visual_findings = str(item.get("visual_findings") or "")

    if evidence_id == "text-resident-1400":
        return {
            "evidence_id": evidence_id,
            "authenticity_score": 0.93,
            "credibility_score": 0.36,
            "verdict": "contradicted",
            "reason": "内容未见伪造迹象，但观察时间最早，已被水位变化和后续图文证据反驳。",
            "extracted_facts": [observed_at, "曾可通行", "信息已过时"],
        }

    if modality == "image":
        latest = "1429" in evidence_id
        return {
            "evidence_id": evidence_id,
            "authenticity_score": 0.96 if latest else 0.91,
            "credibility_score": 0.95 if latest else 0.89,
            "verdict": "supported",
            "reason": (
                "文件指纹存在，OCR 地点与冲突位置一致；视觉特征与相邻时间文字上报相互印证。"
            ),
            "extracted_facts": [
                observed_at,
                item.get("ocr_text") or "未识别到文字",
                visual_findings or "已读取图像内容",
            ],
        }

    is_latest = "无法" in statement or observed_at >= "14:28"
    return {
        "evidence_id": evidence_id,
        "authenticity_score": 0.94 if is_latest else 0.88,
        "credibility_score": 0.93 if is_latest else 0.84,
        "verdict": "supported",
        "reason": "观察时间、地点和描述与两张现场图片形成交叉验证。",
        "extracted_facts": [observed_at, statement],
    }


if __name__ == "__main__":
    print(f"Mock AI backend listening on http://{HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
