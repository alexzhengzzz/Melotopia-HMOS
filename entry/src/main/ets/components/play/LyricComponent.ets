import { EmitterUtil } from "@pura/harmony-utils"
import { Lyric } from "../../common/entities/song/Lyric"
import { seekMusic } from "../../common/functions/play/playControl"
import { LengthUnit } from "@kit.ArkUI"
import { EmitterConstants } from "../../common/constants/EmitterConstants"
import { StorageConstants } from "../../common/constants/StorageConstants"
import { LyricStyle, LyricStyleItem } from "../../common/entities/local/Settings"
import LyricUtils from "../../common/utils/play/LyricUtils"
import { LazyData } from "@pie/lazy-data"

@Component
export struct LyricComponent {
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp(StorageConstants.CURRENT_LYRIC_INDEX) @Watch('ToCurrentLyric') currentLyricIndex: number = 0
  @State firstLoad: boolean = true
  @State userScrolling: number = 0
  @State userScrollingInterval: number = 0
  @State lyric: Lyric[] = []
  @State dataSource: LazyData<Lyric> = new LazyData()
  @State currentListIndex: number = 0
  @StorageProp(StorageConstants.LYRIC_STYLE) lyricStyle: LyricStyle = LyricStyleItem

  private scroller: Scroller = new Scroller()

  async aboutToAppear(): Promise<void> {
    await this.getLyric()
    setTimeout(() => {
      this.scroller.scrollToIndex(this.currentLyricIndex, false, ScrollAlign.CENTER)
    }, 10)
    this.userScrollingInterval = setInterval(() => {
      if(this.userScrolling > 0) this.userScrolling -= 1
      else if(this.userScrolling === 0) {
        this.ToCurrentLyric()
      }
    }, 1000)

    EmitterUtil.onSubscribe(EmitterConstants.EMITTER_LYRIC_UPDATE, async () => {
      this.currentLyricIndex = 0
      await this.getLyric()
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.userScrollingInterval)
  }

  async getLyric() {
    this.dataSource.setData([{ time: 0, content: '⋯'}])
    this.lyric = await LyricUtils.getLyricObjects()
    setTimeout(() => {
      this.dataSource.setData(this.lyric)
      this.dataSource.notifyDataReload()
    }, 200)
  }

  ToCurrentLyric() {
    if(!this.userScrolling) {
      if(this.currentListIndex - this.currentLyricIndex > 6) {
        this.scroller.scrollToIndex(this.currentLyricIndex, false, ScrollAlign.CENTER)
      } else {
        this.scroller.scrollToIndex(this.currentLyricIndex, true, ScrollAlign.CENTER)
      }
      this.currentListIndex = this.currentLyricIndex
    }
  }

  build() {
    List({ scroller: this.scroller }) {
      LazyForEach(this.dataSource, (item: Lyric, index) => {
        ListItem() {
          LyricLine({
            lyricStyle: this.lyricStyle,
            currentLyricIndex: this.currentLyricIndex,
            userScrolling: this.userScrolling,
            index: index,
            item: item
          })
        }
        .offset({ y: this.Offset(index) })
        .padding({
          top: this.userScrolling ? this.lyricStyle.size : this.lyricStyle.size * 0.5,
          bottom: this.userScrolling ? this.lyricStyle.size : this.lyricStyle.size * 0.5
        })
        .animation(this.userScrolling ? { } : {
          delay: this.userScrolling ? 0 : this.Delay(index),
          duration: 500,
          curve: Curve.Smooth,
          expectedFrameRateRange: {
            expected: 90,
            min: 60,
            max: 90
          }
        })
      })
    }
    .cachedCount(15)
    .alignListItem(ListItemAlign.End)
    .padding({ top: 30 })
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring)
    .scrollSnapAlign(ScrollSnapAlign.CENTER)
    .listDirection(Axis.Vertical)
    .cachedCount(20)
    .scrollBar(BarState.Off)
    .fadingEdge(true, {
      fadingEdgeLength: {
        unit: LengthUnit.PERCENT,
        value: 40
      }
    })
    .onScrollIndex((start, end, center) => {
      this.currentListIndex = center
    })
    .onTouch(() => {
      this.userScrolling = 2
    })
  }

  Offset(index: number) {
    if(this.userScrolling) return 0
    const LINE_SPACING = this.lyricStyle.size
    const delta = index - this.currentLyricIndex
    let offset = Math.abs(delta) < 6
      ? delta * LINE_SPACING
      : delta > 0
        ? 6 * LINE_SPACING
        : -6 * LINE_SPACING
    return offset
  }

  Delay(index: number) {
    const delta = index - this.currentLyricIndex
    if(delta > 5) return 6 * 120
    return Math.max(delta * 120, 0)
  }

}

@Reusable
@Component
struct LyricLine {
  @State index: number = 0
  @State item: Lyric = { time: 0, content: ''}
  @Prop currentLyricIndex: number = 0
  @Prop lyricStyle: LyricStyle = LyricStyleItem
  @Link userScrolling: number

  aboutToReuse(params: ESObject): void {
    this.index = params.index
    this.item = params.item as Lyric
  }

  build() {
    Text(this.item.content)
      .width('100%')
      .textAlign(TextAlign.Center)
      .fontSize(this.lyricStyle.size)
      .lineHeight(this.lyricStyle.size * 1.3)
      .fontColor(Color.White)
      .opacity(this.index == this.currentLyricIndex ? 1 : 0.35)
      .fontWeight(FontWeight.Bolder)
      .textAlign(this.lyricStyle.align === 'center' ? TextAlign.Center : TextAlign.Start)
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.9 })
      .padding({ left: 20, right: 20 })
      .onClick(() => {
        seekMusic(this.item.time + 100)
        setTimeout(() => {
          this.userScrolling = 0
        }, 100)
      })
      .animation(this.userScrolling ? { } : {
        duration: 300,
        curve: Curve.Smooth
      })
  }
}
