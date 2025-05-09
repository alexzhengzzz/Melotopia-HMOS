import { EmitterUtil } from "@pura/harmony-utils"
import { Lyric } from "../../common/entities/song/Lyric"
import { seekMusic } from "../../common/functions/play/playControl"
import { LengthUnit } from "@kit.ArkUI"
import { EmitterConstants } from "../../common/constants/EmitterConstants"
import { StorageConstants } from "../../common/constants/StorageConstants"
import { LyricStyle, LyricStyleItem } from "../../common/entities/local/Settings"
import LyricUtils from "../../common/utils/play/LyricUtils"
import { LazyData } from "@pie/lazy-data"
import Constants from "../../common/constants/Constants"

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
  @State isLoading: boolean = false
  @StorageProp(StorageConstants.LYRIC_STYLE) lyricStyle: LyricStyle = LyricStyleItem

  private scroller: Scroller = new Scroller()

  async aboutToAppear(): Promise<void> {
    await this.getLyric()
    setTimeout(() => {
      this.scroller.scrollToIndex(this.currentLyricIndex + 1, false, ScrollAlign.CENTER)
    }, 10)
    this.StartAutoScrollTimer()

    EmitterUtil.onSubscribe(EmitterConstants.EMITTER_LYRIC_UPDATE, async () => {
      this.isLoading = true
      this.currentLyricIndex = 0
      setTimeout(async () => {
        await this.getLyric()
        this.isLoading = false
      }, 100)
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.userScrollingInterval)
  }

  private StartAutoScrollTimer() {
    this.userScrollingInterval = setInterval(() => {
      if(this.userScrolling > 0) {
        this.userScrolling -= 1
      } else if(this.userScrolling === 0 && this.currentListIndex !== this.currentLyricIndex) {
        this.ToCurrentLyric()
      }
    }, 1000)
  }

  async getLyric() {
    this.lyric = await LyricUtils.getLyricObjects()
    this.dataSource.setData(this.lyric)
    this.dataSource.notifyDataReload()
  }

  ToCurrentLyric() {
    if(!this.userScrolling) {
      this.scroller.scrollToIndex(this.currentLyricIndex + 1, true, ScrollAlign.CENTER)
      this.currentListIndex = this.currentLyricIndex
    }
  }

  build() {
    List({ scroller: this.scroller }) {
      if(this.isLoading) {
        ListItem() {
          LoadingProgress().width(Constants.SIZE_LOADING_PROGRESS_DEFAULT)
        }
        .align(Alignment.Center)
        .width('100%')
        .layoutWeight(1)
      } else {
        ListItem().height('30%')
        LazyForEach(this.dataSource, (item: Lyric, index) => {
          LyricLine({
            lyricStyle: this.lyricStyle,
            currentLyricIndex: this.currentLyricIndex,
            userScrolling: this.userScrolling,
            index: index,
            item: item
          })
          .offset({ y: this.Offset(index) })
          .padding({
            bottom: this.userScrolling
              ? this.lyricStyle.size * 2
              : (index - this.currentLyricIndex >= 0 ? this.lyricStyle.size : this.lyricStyle.size * 2)
          })
          .animation({
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
        ListItem().height('30%')
      }
    }
    .cachedCount(5)
    .alignListItem(ListItemAlign.End)
    .padding({ top: 30 })
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring)
    .listDirection(Axis.Vertical)
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
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Move) {
        this.userScrolling = 2
      }
    })
  }

  Offset(index: number) {
    if(this.userScrolling) return 0
    const LINE_SPACING = this.lyricStyle.size
    const delta = index - this.currentLyricIndex
    let offset = delta > 0 ? delta * LINE_SPACING : 0
    return offset
  }

  Delay(index: number) {
    if(this.userScrolling) return 0
    const delta = index - this.currentLyricIndex
    if(delta > 10) return 10 * 60
    return Math.max(delta * 60, 0)
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
      .fontWeight(Constants.FONT_WEIGHT_BOLD)
      .textAlign(this.lyricStyle.align === 'center' ? TextAlign.Center : TextAlign.Start)
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.9 })
      .padding({ left: 20, right: 20 })
      .scale(this.index === this.currentLyricIndex ?
        { x: 1.0, y: 1.0, centerX: this.lyricStyle.align === 'center' ? '50%' : 0 } :
        { x: 0.9, y: 0.9, centerX: this.lyricStyle.align === 'center' ? '50%' : 0 })
      .onClick(() => {
        seekMusic(this.item.time + 100)
        setTimeout(() => {
          this.userScrolling = 0
        }, 100)
      })
      .animation({
        duration: 500,
        curve: Curve.Smooth
      })
  }
}
