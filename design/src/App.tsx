import { useState } from 'react'

// ── 色彩系统（教堂彩窗色板）──
const C = {
  bg: '#F7F4EF',
  mapLine: '#E6E0D5',
  lead: '#2E2A26',
  red: '#A63A46',
  blue: '#2456A6',
  amber: '#D9A441',
  green: '#2E7D5B',
  purple: '#6B4E9B',
  hole: '#0B0A0C',
  white: '#FFFFFF',
}

// ── Mock 碎片数据 ──
const FRAGMENTS = [
  { id: 1, type: 'people', shape: 'circle', label: 'A 社区', sub: '运河西岸 · 60人被困', color: C.amber, status: 'normal', time: '14:10' },
  { id: 2, type: 'supply', shape: 'triangle', label: 'B 仓库', sub: '饮用水 200箱', color: C.green, status: 'normal', time: '14:15' },
  { id: 3, type: 'medical', shape: 'cross', label: 'C 医院', sub: '剩余 12 床位', color: C.red, status: 'normal', time: '14:20' },
  { id: 4, type: 'road', shape: 'bar', label: '沿江路', sub: '14:00 车辆可通行（居民）', color: C.blue, status: 'conflict', time: '14:00' },
  { id: 5, type: 'road', shape: 'bar', label: '沿江路', sub: '14:28 路面已被淹（司机）', color: C.blue, status: 'conflict', time: '14:28' },
  { id: 6, type: 'shelter', shape: 'diamond', label: '文体中心', sub: '避难所 · 容纳 200人', color: C.purple, status: 'normal', time: '14:05' },
  { id: 7, type: 'unknown', shape: 'hole', label: '大关桥', sub: '通行状态未知 · 影响3条路线', color: C.hole, status: 'blind', time: '' },
]

type Screen = 'command' | 'resident' | 'question' | 'success'
type FragmentStatus = 'normal' | 'conflict' | 'blind'

// ── 形状图标组件 ──
function ShapeIcon({ shape, color, size = 20 }: { shape: string; color: string; size?: number }) {
  const s = size
  if (shape === 'circle') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <circle cx="10" cy="10" r="8" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
      </svg>
    )
  }
  if (shape === 'triangle') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <polygon points="10,2 18,18 2,18" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
      </svg>
    )
  }
  if (shape === 'cross') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <rect x="8" y="2" width="4" height="16" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
        <rect x="2" y="8" width="16" height="4" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
      </svg>
    )
  }
  if (shape === 'bar') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <rect x="2" y="7" width="16" height="6" rx="1" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
      </svg>
    )
  }
  if (shape === 'diamond') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <polygon points="10,1 19,10 10,19 1,10" fill={color} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.5" />
      </svg>
    )
  }
  if (shape === 'hole') {
    return (
      <svg width={s} height={s} viewBox="0 0 20 20">
        <circle cx="10" cy="10" r="8" fill={color} stroke={C.lead} strokeWidth="1.5" />
        <circle cx="10" cy="10" r="3" fill={C.bg} opacity={0.3} />
      </svg>
    )
  }
  return null
}

// ── 扁平线稿地图 ──
function MapView({ conflictResolved }: { conflictResolved?: boolean }) {
  return (
    <div style={{ background: C.bg, borderBottom: `1px solid ${C.mapLine}` }} className="relative w-full overflow-hidden">
      <svg
        viewBox="0 0 360 200"
        className="w-full"
        style={{ height: 200, display: 'block' }}
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 背景 */}
        <rect width="360" height="200" fill={C.bg} />

        {/* 运河（京杭大运河）—— 蓝色水道 */}
        <path d="M 60 40 Q 100 60 140 80 Q 180 100 220 110 Q 260 120 300 130" stroke="#A8C8E8" strokeWidth="14" fill="none" strokeLinecap="round" opacity={0.5} />
        <path d="M 60 40 Q 100 60 140 80 Q 180 100 220 110 Q 260 120 300 130" stroke="#C8DFF0" strokeWidth="10" fill="none" strokeLinecap="round" opacity={0.4} />

        {/* 道路网格 */}
        {/* 主干道横向 */}
        <line x1="20" y1="90" x2="340" y2="90" stroke={C.mapLine} strokeWidth="2" />
        <line x1="20" y1="140" x2="340" y2="140" stroke={C.mapLine} strokeWidth="1.5" />
        <line x1="20" y1="60" x2="340" y2="60" stroke={C.mapLine} strokeWidth="1" />
        {/* 主干道纵向 */}
        <line x1="80" y1="20" x2="80" y2="180" stroke={C.mapLine} strokeWidth="2" />
        <line x1="160" y1="20" x2="160" y2="180" stroke={C.mapLine} strokeWidth="1.5" />
        <line x1="240" y1="20" x2="240" y2="180" stroke={C.mapLine} strokeWidth="2" />
        <line x1="300" y1="20" x2="300" y2="180" stroke={C.mapLine} strokeWidth="1" />

        {/* 沿江路标注 */}
        <text x="22" y="86" fontSize="7" fill={C.lead} opacity={0.6} fontFamily="system-ui">沿江路</text>

        {/* 大关桥（黑洞） —— 位置 160,90 */}
        <circle cx="160" cy="90" r="12" fill={C.hole} opacity={0.85} />
        <circle cx="160" cy="90" r="5" fill={C.bg} opacity={0.2} />
        <text x="160" y="108" textAnchor="middle" fontSize="7" fill={C.lead} fontFamily="system-ui" opacity={0.7}>大关桥</text>

        {/* 沿江路冲突碎片对 —— 重叠 */}
        {!conflictResolved ? (
          <>
            <rect x="62" y="83" width="28" height="9" rx="1" fill={C.blue} fillOpacity={0.8} stroke={C.lead} strokeWidth="1" />
            <rect x="66" y="87" width="28" height="9" rx="1" fill={C.blue} fillOpacity={0.65} stroke={C.lead} strokeWidth="1" />
            {/* 冲突闪烁点 */}
            <circle cx="75" cy="82" r="3" fill={C.amber} stroke={C.lead} strokeWidth="0.8" />
          </>
        ) : (
          <rect x="64" y="85" width="28" height="9" rx="1" fill={C.red} fillOpacity={0.85} stroke={C.lead} strokeWidth="1" />
        )}

        {/* A 社区圆形（琥珀） */}
        <circle cx="55" cy="130" r="9" fill={C.amber} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.2" />
        <text x="55" y="134" textAnchor="middle" fontSize="6" fill={C.lead} fontFamily="system-ui" fontWeight="600">A</text>
        <text x="55" y="148" textAnchor="middle" fontSize="6" fill={C.lead} fontFamily="system-ui" opacity={0.7}>社区</text>

        {/* B 仓库三角（祖母绿） */}
        <polygon points="240,55 250,75 230,75" fill={C.green} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.2" />
        <text x="240" y="86" textAnchor="middle" fontSize="6" fill={C.lead} fontFamily="system-ui" opacity={0.7}>B仓库</text>

        {/* C 医院十字（宝石红） */}
        <rect x="293" y="118" width="4" height="14" fill={C.red} fillOpacity={0.8} stroke={C.lead} strokeWidth="0.8" />
        <rect x="288" y="123" width="14" height="4" fill={C.red} fillOpacity={0.8} stroke={C.lead} strokeWidth="0.8" />
        <text x="300" y="140" textAnchor="middle" fontSize="6" fill={C.lead} fontFamily="system-ui" opacity={0.7}>C医院</text>

        {/* 文体中心菱形（紫晶） */}
        <polygon points="110,150 120,160 110,170 100,160" fill={C.purple} fillOpacity={0.75} stroke={C.lead} strokeWidth="1.2" />
        <text x="110" y="180" textAnchor="middle" fontSize="6" fill={C.lead} fontFamily="system-ui" opacity={0.7}>文体中心</text>

        {/* 水印 */}
        <text x="340" y="195" textAnchor="end" fontSize="6" fill={C.lead} opacity={0.35} fontFamily="system-ui">模拟演练数据 · 杭州</text>
      </svg>
    </div>
  )
}

// ── 碎片卡片 ──
function FragmentCard({ frag, isConflict }: { frag: typeof FRAGMENTS[0]; isConflict?: boolean }) {
  const isBlind = frag.status === 'blind'
  return (
    <div
      className="flex items-center gap-3 px-4 py-3.5 mx-4 mb-3 rounded-2xl shadow-sm transition-transform active:scale-95"
      style={{
        background: isBlind ? C.hole : C.white,
        border: `1px solid ${isConflict ? `${C.amber}50` : 'rgba(46, 42, 38, 0.05)'}`,
        boxShadow: isConflict ? `0 4px 12px ${C.amber}20` : '0 2px 10px rgba(0,0,0,0.04)',
        opacity: isBlind ? 0.95 : 1,
      }}
    >
      <div className="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-xl" style={{ background: `${isBlind ? '#333' : frag.color}15` }}>
        <ShapeIcon shape={frag.shape} color={isBlind ? '#888' : frag.color} size={20} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span
            className="text-base font-semibold tracking-tight"
            style={{ color: isBlind ? '#ccc' : C.lead, fontFamily: 'system-ui' }}
          >
            {frag.label}
          </span>
          {isConflict && (
            <span
              className="text-[10px] px-2 py-0.5 font-bold rounded-full uppercase tracking-wider"
              style={{ background: `${C.amber}20`, color: C.amber }}
            >
              冲突
            </span>
          )}
          {isBlind && (
            <span
              className="text-[10px] px-2 py-0.5 font-bold rounded-full uppercase tracking-wider"
              style={{ background: '#333', color: '#eee' }}
            >
              盲区
            </span>
          )}
        </div>
        <div className="text-sm mt-0.5 truncate font-medium" style={{ color: isBlind ? '#999' : '#8A8580', fontFamily: 'system-ui' }}>
          {frag.sub}
        </div>
      </div>
      {frag.time && (
        <span className="text-sm font-medium shrink-0" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>
          {frag.time}
        </span>
      )}
    </div>
  )
}

// ── 指挥视角 ──
function CommandView() {
  const [priorityTab, setPriorityTab] = useState<'high' | 'medium' | 'low'>('high')
  const [analyzing, setAnalyzing] = useState(false)
  const [resolved, setResolved] = useState(false)

  const finalFragments = resolved
    ? FRAGMENTS.map(f =>
        f.id === 4 ? null : f.id === 5 ? { ...f, status: 'normal', sub: '14:28 路面已被淹 (已确认)', color: C.red } : f
      ).filter(Boolean) as typeof FRAGMENTS
    : FRAGMENTS

  return (
    <div className="flex flex-col h-full overflow-hidden" style={{ background: C.bg }}>
      {/* 状态栏 */}
      <div
        className="flex items-center justify-between px-5 py-3 shrink-0 relative z-20"
        style={{ background: C.lead, color: C.bg, boxShadow: '0 2px 10px rgba(0,0,0,0.1)' }}
      >
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold tracking-widest" style={{ fontFamily: 'system-ui' }}>
            杭州 · 洪灾
          </span>
          <span className="text-xs opacity-60">14:35</span>
        </div>
        <div className="flex items-center gap-3 text-xs font-medium opacity-90">
          <span>碎片 <strong>{resolved ? 26 : 27}</strong></span>
          <span>盲区 <strong>1</strong></span>
          {!resolved && <span style={{ color: C.amber }}>冲突 <strong>1</strong></span>}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto pb-6 relative z-10">
        {/* 地图 */}
        <div className="shrink-0 px-0 mb-4 bg-white shadow-sm" style={{ borderBottom: `1px solid rgba(46, 42, 38, 0.08)` }}>
          <MapView conflictResolved={resolved} />
        </div>

        {/* 优先级信息确认 Tabs */}
        <div className="px-4 mb-4">
          <div className="flex p-1 rounded-2xl shadow-inner" style={{ background: 'rgba(46, 42, 38, 0.04)' }}>
            {(['high', 'medium', 'low'] as const).map(p => (
              <button
                key={p}
                onClick={() => setPriorityTab(p)}
                className="flex-1 py-2.5 text-xs font-bold rounded-xl transition-all relative"
                style={{
                  background: priorityTab === p ? C.white : 'transparent',
                  color: priorityTab === p ? C.lead : '#A5A09A',
                  boxShadow: priorityTab === p ? '0 2px 8px rgba(0,0,0,0.05)' : 'none',
                  fontFamily: 'system-ui'
                }}
              >
                {p === 'high' ? '高优先级' : p === 'medium' ? '中优先级' : '低优先级'}
                {p === 'high' && !resolved && (
                  <span className="absolute top-1.5 right-2 flex items-center justify-center w-4 h-4 rounded-full text-[9px] shadow-sm" style={{ background: C.red, color: C.white }}>2</span>
                )}
                {p === 'high' && resolved && (
                  <span className="absolute top-1.5 right-2 flex items-center justify-center w-4 h-4 rounded-full text-[9px] shadow-sm" style={{ background: C.red, color: C.white }}>1</span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* 确认面板 */}
        {priorityTab === 'high' && (
          <div className="px-4 flex flex-col gap-4 mb-6">
            {!resolved && (
              <div
                className="flex flex-col p-4 rounded-3xl shadow-sm transition-all"
                style={{ background: C.white, border: `1px solid ${C.red}40`, boxShadow: `0 8px 24px ${C.red}15` }}
              >
                <div className="flex items-center justify-between mb-3">
                  <span className="text-[10px] font-bold px-2 py-1 rounded-full tracking-widest uppercase" style={{ background: `${C.red}15`, color: C.red, fontFamily: 'system-ui' }}>
                    逻辑冲突
                  </span>
                  <span className="text-xs font-medium" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>14:28 更新</span>
                </div>
                <div className="text-lg font-bold mb-1.5 leading-tight" style={{ color: C.lead, fontFamily: 'system-ui' }}>沿江路通行状态冲突</div>
                <div className="text-sm font-medium leading-relaxed mb-4" style={{ color: '#8A8580', fontFamily: 'system-ui' }}>
                  同一地点收到两条截然相反的情报，请人工介入研判。
                </div>

                {!analyzing ? (
                  <button
                    onClick={() => setAnalyzing(true)}
                    className="w-full py-3.5 text-sm font-bold tracking-wider rounded-2xl transition-transform active:scale-95"
                    style={{ background: `${C.red}10`, color: C.red, border: `1px solid ${C.red}20`, fontFamily: 'system-ui' }}
                  >
                    进行分析判断
                  </button>
                ) : (
                  <div className="flex flex-col pt-4 mt-1" style={{ borderTop: '1px dashed #E6E0D5' }}>
                    <div className="flex items-center gap-2 mb-4">
                      <span style={{ fontSize: 16 }}>💡</span>
                      <span className="text-sm font-bold" style={{ color: C.lead, fontFamily: 'system-ui' }}>系统推断：水位上涨中，建议采信最新上报</span>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="flex flex-col p-3 rounded-2xl" style={{ border: '1px solid rgba(46, 42, 38, 0.08)', background: '#F7F4EF' }}>
                        <div className="text-[10px] font-bold uppercase tracking-wider mb-1.5" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>14:00 · 居民</div>
                        <div className="text-sm font-bold mb-4" style={{ color: C.lead, fontFamily: 'system-ui' }}>车辆可通行</div>
                        <button className="mt-auto py-2.5 text-xs font-bold rounded-xl transition-transform active:scale-95" style={{ background: C.white, color: C.lead, border: '1px solid rgba(46, 42, 38, 0.1)', fontFamily: 'system-ui' }}>
                          采信此条
                        </button>
                      </div>
                      <div className="flex flex-col p-3 rounded-2xl relative" style={{ border: `1.5px solid ${C.red}`, background: `${C.red}05` }}>
                        <div className="absolute -top-2.5 -right-2 text-[10px] font-bold px-2 py-0.5 rounded-full shadow-sm" style={{ background: C.red, color: C.white, fontFamily: 'system-ui' }}>推荐</div>
                        <div className="text-[10px] font-bold uppercase tracking-wider mb-1.5" style={{ color: C.red, opacity: 0.8, fontFamily: 'system-ui' }}>14:28 · 司机</div>
                        <div className="text-sm font-bold mb-4" style={{ color: C.red, fontFamily: 'system-ui' }}>路面已被淹</div>
                        <button
                          onClick={() => setResolved(true)}
                          className="mt-auto py-2.5 text-xs font-bold rounded-xl transition-transform active:scale-95"
                          style={{ background: C.red, color: C.white, border: 'none', fontFamily: 'system-ui', boxShadow: `0 4px 12px ${C.red}40` }}
                        >
                          采信此条
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* 盲区卡片 */}
            <div
              className="flex flex-col p-4 rounded-3xl shadow-sm"
              style={{ background: C.white, border: '1px solid rgba(46, 42, 38, 0.08)' }}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-[10px] font-bold px-2 py-1 rounded-full tracking-widest uppercase" style={{ background: 'rgba(46, 42, 38, 0.05)', color: C.lead, fontFamily: 'system-ui' }}>
                  严重盲区
                </span>
                <span className="text-xs font-medium" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>影响 60 人</span>
              </div>
              <div className="text-lg font-bold mb-1.5 leading-tight" style={{ color: C.lead, fontFamily: 'system-ui' }}>大关桥通行状态未知</div>
              <div className="text-sm font-medium leading-relaxed" style={{ color: '#8A8580', fontFamily: 'system-ui' }}>
                影响 3 条配送路线，系统已向附近居民下发定向确认请求。
              </div>
            </div>
          </div>
        )}

        {priorityTab === 'medium' && (
          <div className="px-4 mb-6 text-center text-sm font-medium py-10 rounded-3xl" style={{ color: '#A5A09A', border: '1px dashed rgba(46, 42, 38, 0.1)', fontFamily: 'system-ui' }}>
            当前无中优先级待确认信息
          </div>
        )}

        {priorityTab === 'low' && (
          <div className="px-4 mb-6 text-center text-sm font-medium py-10 rounded-3xl" style={{ color: '#A5A09A', border: '1px dashed rgba(46, 42, 38, 0.1)', fontFamily: 'system-ui' }}>
            当前无低优先级待确认信息
          </div>
        )}

        {/* 碎片列表 */}
        <div className="px-5 py-2 mb-1 text-[11px] font-bold tracking-widest uppercase flex items-center justify-between" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>
          <span>全量信息碎片</span>
          <span className="px-2 py-0.5 rounded-full" style={{ background: 'rgba(46, 42, 38, 0.05)' }}>{finalFragments.length}</span>
        </div>
        <div className="flex flex-col">
          {finalFragments.map((f, i) => {
            const isConflict = f.status === 'conflict'
            const prevIsConflict = i > 0 && finalFragments[i - 1].status === 'conflict'
            if (isConflict && prevIsConflict) return null
            if (isConflict) {
              return (
                <div key={f.id} className="relative">
                  <div className="absolute left-10 top-8 bottom-8 w-px border-l-2 border-dashed z-10" style={{ borderColor: `${C.amber}60` }} />
                  <FragmentCard frag={f} isConflict />
                  <FragmentCard frag={finalFragments[i + 1]} isConflict />
                </div>
              )
            }
            return (
              <FragmentCard key={f.id} frag={f} />
            )
          })}
        </div>
      </div>
    </div>
  )
}

// ── 居民端：问题页 ──
const OPTIONS = [
  { id: 'a', label: '车辆可通行' },
  { id: 'b', label: '仅行人可通行' },
  { id: 'c', label: '完全中断' },
  { id: 'd', label: '无法判断' },
]

function QuestionView({ onSuccess }: { onSuccess: () => void }) {
  const [selected, setSelected] = useState<string | null>(null)
  const [sending, setSending] = useState(false)

  const handleSubmit = () => {
    if (!selected || sending) return
    setSending(true)
    setTimeout(() => onSuccess(), 1200)
  }

  return (
    <div className="flex flex-col h-full" style={{ background: C.bg }}>
      {/* 顶部 */}
      <div className="px-6 pt-10 pb-6 shrink-0">
        <div className="text-[11px] font-bold tracking-widest uppercase mb-3 px-2.5 py-1 inline-block rounded-full" style={{ background: `${C.amber}20`, color: '#B38128', fontFamily: 'system-ui' }}>
          定向确认请求
        </div>
        <div className="text-2xl font-bold leading-tight" style={{ color: C.lead, fontFamily: 'system-ui' }}>
          你现在能看见大关桥吗？
        </div>
        <div className="text-base mt-3 font-medium leading-relaxed" style={{ color: '#8A8580', fontFamily: 'system-ui' }}>
          大关桥目前通行状态未知，影响 3 条救援路线。
        </div>
      </div>

      {/* 选项 */}
      <div className="flex-1 px-5 pt-2 flex flex-col gap-3">
        {OPTIONS.map(opt => (
          <button
            key={opt.id}
            onClick={() => setSelected(opt.id)}
            className="w-full text-left px-5 py-4 text-base font-bold transition-all"
            style={{
              background: selected === opt.id ? C.blue : C.white,
              color: selected === opt.id ? C.white : C.lead,
              border: `1px solid ${selected === opt.id ? C.blue : 'rgba(46, 42, 38, 0.08)'}`,
              boxShadow: selected === opt.id ? `0 8px 24px ${C.blue}40` : '0 2px 10px rgba(0,0,0,0.03)',
              fontFamily: 'system-ui',
              borderRadius: '20px',
              transform: selected === opt.id ? 'scale(1.02)' : 'scale(1)',
            }}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {/* 提交 */}
      <div className="px-5 py-6 shrink-0 mt-auto">
        <button
          onClick={handleSubmit}
          disabled={!selected || sending}
          className="w-full py-4 text-base font-bold tracking-wider rounded-2xl transition-all"
          style={{
            background: selected && !sending ? C.lead : 'rgba(46, 42, 38, 0.1)',
            color: selected && !sending ? C.white : 'rgba(46, 42, 38, 0.4)',
            border: 'none',
            fontFamily: 'system-ui',
            boxShadow: selected && !sending ? '0 8px 24px rgba(46, 42, 38, 0.2)' : 'none',
            cursor: selected && !sending ? 'pointer' : 'not-allowed',
          }}
        >
          {sending ? '提交中…' : '提交'}
        </button>
        <div className="text-center text-xs mt-4 font-medium" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>
          匿名上报 · 无需注册
        </div>
      </div>
    </div>
  )
}

// ── 居民端：成功页 ──
function SuccessView({ onBack }: { onBack: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full px-8 text-center" style={{ background: C.bg }}>
      <div className="flex items-center justify-center w-24 h-24 rounded-full mb-8 shadow-sm" style={{ background: C.white, border: '1px solid rgba(46, 42, 38, 0.05)', boxShadow: '0 8px 32px rgba(46, 125, 91, 0.15)' }}>
        <svg width="48" height="48" viewBox="0 0 56 56">
          <circle cx="28" cy="28" r="28" fill={`${C.green}20`} />
          <polyline points="16,28 24,36 40,20" stroke={C.green} strokeWidth="4" fill="none" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div className="text-2xl font-bold mb-3 tracking-tight" style={{ color: C.lead, fontFamily: 'system-ui' }}>
        已收到你的碎片
      </div>
      <div className="text-base mb-6 font-medium leading-relaxed" style={{ color: '#8A8580', fontFamily: 'system-ui' }}>
        你的信息正在影响{' '}
        <strong style={{ color: C.green }}>3 条救援路线</strong>
      </div>
      <div className="px-4 py-2 rounded-xl mb-12 text-sm font-bold" style={{ background: 'rgba(46, 42, 38, 0.04)', color: '#A5A09A', fontFamily: 'system-ui' }}>
        仅行人可通行 · 大关桥 · 14:35
      </div>
      <button
        onClick={onBack}
        className="w-full py-4 text-base font-bold tracking-wider rounded-2xl transition-transform active:scale-95"
        style={{ background: C.lead, color: C.white, border: 'none', fontFamily: 'system-ui', boxShadow: '0 8px 24px rgba(46, 42, 38, 0.2)' }}
      >
        返回首页
      </button>
    </div>
  )
}

// ── 居民端首页 ──
const REPORT_BTNS = [
  { icon: '🆘', label: '需要救援', color: C.red },
  { icon: '🏥', label: '医疗紧急', color: C.red },
  { icon: '💧', label: '缺少饮水', color: C.blue },
  { icon: '🍱', label: '缺少食物', color: C.amber },
  { icon: '🏠', label: '需要避难', color: C.purple },
  { icon: '🛣️', label: '上报道路', color: C.blue },
]

function ResidentHome({ onTask }: { onTask: () => void }) {
  return (
    <div className="flex flex-col h-full overflow-y-auto pt-4" style={{ background: C.bg }}>
      {/* 任务卡 */}
      <div
        className="mx-4 mb-6 p-5 cursor-pointer rounded-3xl shadow-sm transition-transform active:scale-[0.98]"
        onClick={onTask}
        style={{
          background: C.white,
          border: `1px solid ${C.amber}40`,
          boxShadow: `0 8px 24px ${C.amber}20`,
        }}
      >
        <div className="flex items-center gap-2 mb-2">
          <span className="text-[11px] font-bold tracking-widest uppercase px-2 py-1 rounded-full" style={{ background: `${C.amber}15`, color: C.amber, fontFamily: 'system-ui' }}>
            定向确认请求
          </span>
        </div>
        <div className="text-xl font-bold leading-tight" style={{ color: C.lead, fontFamily: 'system-ui' }}>
          你现在能看见大关桥吗？
        </div>
        <div className="text-sm mt-2 font-medium" style={{ color: '#8A8580', fontFamily: 'system-ui' }}>
          点击回答 · 影响 3 条救援路线
        </div>
      </div>

      {/* 提示 */}
      <div className="px-5 mb-4 text-base font-bold" style={{ color: C.lead, fontFamily: 'system-ui' }}>
        你需要什么帮助？
      </div>

      {/* 6 按钮宫格 */}
      <div className="px-4 grid grid-cols-2 gap-3 mb-6">
        {REPORT_BTNS.map((btn) => (
          <button
            key={btn.label}
            className="flex flex-col items-center justify-center py-6 gap-3 rounded-3xl transition-transform active:scale-95"
            style={{
              background: C.white,
              border: '1px solid rgba(46, 42, 38, 0.05)',
              boxShadow: '0 4px 16px rgba(0,0,0,0.04)',
              fontFamily: 'system-ui',
            }}
            onClick={btn.label === '上报道路' ? onTask : undefined}
          >
            <div className="flex items-center justify-center w-14 h-14 rounded-2xl" style={{ background: `${btn.color}10` }}>
              <span style={{ fontSize: 26, filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))' }}>{btn.icon}</span>
            </div>
            <span className="text-sm font-bold" style={{ color: C.lead }}>
              {btn.label}
            </span>
          </button>
        ))}
      </div>

      {/* 底部说明 */}
      <div className="text-center text-xs py-4 mt-auto font-medium" style={{ color: '#A5A09A', fontFamily: 'system-ui' }}>
        无需注册 · 匿名上报 · 支持离线
      </div>
    </div>
  )
}

// ── 底部 Tab ──
function TabBar({ active, onChange }: { active: string; onChange: (v: string) => void }) {
  return (
    <div
      className="flex shrink-0 pb-safe pt-2 px-4 mb-4 gap-3"
      style={{ background: 'transparent' }}
    >
      {[
        { id: 'command', label: '指挥视角', icon: '⊕' },
        { id: 'resident', label: '居民上报', icon: '◎' },
      ].map(tab => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className="flex-1 flex flex-col items-center py-3 gap-1 text-[11px] font-bold tracking-wider rounded-2xl transition-all"
          style={{
            background: active === tab.id ? C.lead : C.white,
            color: active === tab.id ? C.white : '#A5A09A',
            border: active === tab.id ? 'none' : '1px solid rgba(46, 42, 38, 0.08)',
            boxShadow: active === tab.id ? '0 8px 24px rgba(46, 42, 38, 0.2)' : '0 2px 10px rgba(0,0,0,0.03)',
            fontFamily: 'system-ui',
          }}
        >
          <span style={{ fontSize: 20, lineHeight: 1 }}>{tab.icon}</span>
          <span>{tab.label}</span>
        </button>
      ))}
    </div>
  )
}

// ── 根组件 ──
export default function App() {
  const [tab, setTab] = useState<'command' | 'resident'>('command')
  const [screen, setScreen] = useState<Screen>('command')

  const handleTabChange = (v: string) => {
    setTab(v as 'command' | 'resident')
    setScreen(v as Screen)
  }

  const handleTask = () => setScreen('question')
  const handleSuccess = () => setScreen('success')
  const handleBack = () => {
    setScreen('resident')
  }

  const showTab = screen === 'command' || screen === 'resident'

  return (
    <div
      className="flex flex-col mx-auto"
      style={{
        maxWidth: 393,
        height: '100dvh',
        background: C.bg,
        fontFamily: 'system-ui, -apple-system, sans-serif',
        overflow: 'hidden',
      }}
    >
      {/* 内容区 */}
      <div className="flex-1 overflow-hidden flex flex-col">
        {screen === 'command' && <CommandView />}
        {screen === 'resident' && <ResidentHome onTask={handleTask} />}
        {screen === 'question' && <QuestionView onSuccess={handleSuccess} />}
        {screen === 'success' && <SuccessView onBack={handleBack} />}
      </div>

      {/* Tab 栏（问题页和成功页隐藏） */}
      {showTab && <TabBar active={tab} onChange={handleTabChange} />}
    </div>
  )
}
