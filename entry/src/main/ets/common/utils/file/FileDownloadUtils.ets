import { common } from '@kit.AbilityKit'
import { BusinessError, request } from '@kit.BasicServicesKit'
import { SongDownload } from '../../entities/song/SongDownload'
import { Song } from '../../entities/song/Song'
import { DialogUtil, FileUtil, LogUtil, ToastUtil } from '@pura/harmony-utils'
import { promptAction } from '@kit.ArkUI'
import { changeb2Mb, sanitizeFileName } from '../../functions/common/convert'
import FileUtils from './FileUtils'
import { MsgConstants } from '../../constants/MsgConstants'
import NotificationUtils from '../system/NotificationUtils'
import fileIo from '@ohos.file.fs'
import RelationalStoreUtils from '../data/RelationalStoreUtils'

/**
 * 文件缓存
 */

const TAG = '[FileDownload] '

class FileDownloadUtils {
  context = getContext(this) as common.UIAbilityContext
  filesDir = this.context.filesDir
  cacheDir = this.context.cacheDir

  async downloadSong(songDownload: SongDownload, song: Song, artists: string) {
    if(song.name.length + artists.length >= 103) {
      try {
        artists = artists.slice(0, 100 - song.name.length)
      } catch (e) {
        artists = 'null'
      }
    }

    let fileName = sanitizeFileName(`${artists} - ${song.name}.${songDownload.data[0].type}`)
    let cachePath = this.cacheDir + `/${fileName}`
    let descPath = this.filesDir + `/${fileName}`
    if(await FileUtil.access(descPath)) {
      DialogUtil.showConfirmDialog({ title:'提示', message:'文件已存在'})
      return
    }
    else {
      try {
        ToastUtil.showToast(`开始下载：${song.name}.${songDownload.data[0].type}`)
        request.downloadFile(this.context, {
          url: songDownload.data[0].url,
          filePath: cachePath
        }).then(async (downloadTask: request.DownloadTask) => {
          downloadTask.on('progress', async (received, total) => {
            NotificationUtils.download(song.id, MsgConstants.DOWNLOADING, `${song.name} - ${artists}`, changeb2Mb(received)/changeb2Mb(total)*100)
          })
          downloadTask.on('complete', () => {
            FileUtils.moveFile(cachePath, descPath).then(() => {
              NotificationUtils.download(song.id, MsgConstants.DOWNLOAD_COMPLETE, `${song.name} - ${artists}`, 100)
              ToastUtil.showToast(`缓存完成: ${song.name}`)
              RelationalStoreUtils.addSong({
                id: 0,
                songId: song.id,
                name: song.name,
                artists: JSON.stringify(song.artists),
                picFile: "",
                songFile: fileName,
                lyricFile: ""
              })
            })
          })
        }).catch((err: BusinessError) => {
          ToastUtil.showToast('缓存时出错: ' + err.message)
          LogUtil.error(TAG, `缓存时出错: ${JSON.stringify(err)}`)
          FileUtils.deleteFile([{
            id: 0,
            name: song.name,
            artists: artists,
            songId: 0,
            songFile: `${artists} - ${song.name}.${songDownload.data[0].type}`,
            picFile: '',
            lyricFile: ''
          }])
        })
      } catch (error) {
        let err: BusinessError = error as BusinessError
        NotificationUtils.cancel(song.id)
        if (err.code == 13400002) {
          DialogUtil.showConfirmDialog({ title: '提示', message: `文件已存在` })
        } else {
          DialogUtil.showConfirmDialog({ title: '缓存失败', message: `${err.message}` })
        }
        LogUtil.error(TAG, '下载出错: ' + err.message)
      }
    }
  }

  async download(url: string, fileName: string, dir: string = '') {
    const targetDir = dir ? `${this.filesDir}/${dir}` : this.filesDir
    const cachePath = `${this.cacheDir}/${fileName}`
    const descPath = `${targetDir}/${fileName}`
    if(dir && !fileIo.accessSync(targetDir)) fileIo.mkdirSync(targetDir)
    try {
      request.downloadFile(this.context, {
        url: url,
        filePath: cachePath
      }).then((downloadTask: request.DownloadTask) => {
        downloadTask.on('complete', () => {
          FileUtils.moveFile(cachePath, descPath)
        })
      })
    } catch (e) {
      LogUtil.error(TAG, 'Download Error: ' + e.message)
    }
  }
}

const fileDownload = new FileDownloadUtils()
export default fileDownload as FileDownloadUtils
