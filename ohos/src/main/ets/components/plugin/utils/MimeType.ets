/*
 * Copyright (c) 2021-2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export class MimeType {
  /**
   * 文件大分类：图片
   */
  public static FILE_CATEGORY_IMAGE = 1

  /**
   * 文件大分类：视频
   */
  public static FILE_CATEGORY_VIDEO = 2

  /**
   * 文件大分类：音频
   */
  public static FILE_CATEGORY_AUDIO = 3

  /**
   * 文件大分类：文档
   */
  public static FILE_CATEGORY_TXT = 4

  /**
   * 文件大分类：压缩包
   */
  public static FILE_CATEGORY_ZIP = 5

  /**
   * 文件大分类：APK
   */
  public static FILE_CATEGORY_PKG = 6

  /**
   * 文件大分类：未知
   */
  public static FILE_CATEGORY_UNKNOW = 7

  /**
   * 文件后缀对应的整形定义，用于文件的大分类
   */
  private fileCategory: number

  /**
   * 文件后缀对应的整形定义，用于文件细分的类型
   */
  private fileTypeSort: number


  /**
   * 文件的mimetype
   */
  private mimeType: string

  /**
   * 文件后缀
   */
  private extension: string

  constructor(extension: string, fileCategory: number, fileTypeSort: number,  mimeType: string) {
    this.extension = extension
    this.fileCategory = fileCategory
    this.fileTypeSort = fileTypeSort
    this.mimeType = mimeType
  }

  getFileCategory(): number {
    return this.fileCategory
  }

  getMimeType(){
    return this.mimeType
  }

  getFileTypeSort(): number {
    return this.fileTypeSort
  }


  isMedia(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_IMAGE || this.fileCategory === MimeType.FILE_CATEGORY_VIDEO || this.fileCategory === MimeType.FILE_CATEGORY_AUDIO
  }

  isAudioOrVideo(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_VIDEO || this.fileCategory === MimeType.FILE_CATEGORY_AUDIO
  }

  isDoc(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_TXT
  }

  isAudio(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_AUDIO
  }

  isVideo(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_VIDEO
  }

  isImage(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_IMAGE
  }

  isZip(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_ZIP
  }

  isPKG(): boolean {
    return this.fileCategory === MimeType.FILE_CATEGORY_PKG
  }
}