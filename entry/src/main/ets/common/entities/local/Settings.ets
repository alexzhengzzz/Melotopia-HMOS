/**
 * 歌词样式
 */
export interface LyricStyle {
  size: number
  color: ResourceColor | string
  align: 'center' | 'start'
  mode: number // 0 - Normal, 1 - Translate, 2 - Roma
}

export interface LyricPosition {
  x: number,
  y: number
}

export interface FloatLyric {
  on: boolean
  position: LyricPosition
  size: number
  width: number
  lines: number
  align: 'start' | 'center' | 'end'
  bgBlur: boolean
  touchable: boolean
  opacity: number
  color: string | ResourceStr
  movable: boolean
}

/**
 * 缓存设置
 */
export interface CacheSet {
  songCacheMaxSize: number
  staticCacheMaxSize: number
}

export const CacheSetItem: CacheSet = {
  songCacheMaxSize: 1024 * 1024 * 1024,
  staticCacheMaxSize: 1024 * 1024 * 1024
}

export const LyricStyleItem: LyricStyle = {
  size: 20,
  color: Color.White,
  align: 'center',
  mode: 0
}

export const FloatLyricItem: FloatLyric = {
  on: false,
  position: {
    x: 0,
    y: 30
  },
  size: 16,
  color: $r('app.color.app_red'),
  align: 'center',
  lines: 1,
  opacity: 1.0,
  touchable: true,
  bgBlur: false,
  width: 100,
  movable: false
}