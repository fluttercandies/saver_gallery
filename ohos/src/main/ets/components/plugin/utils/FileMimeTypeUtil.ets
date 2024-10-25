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

import { MimeType } from './MimeType'
import StringUtil from './StringUtil'

/**
 * 文件媒体类型
 */
export class FileMimeTypeUtil {
  /**
   * Image file types
   */
  public static FILE_TYPE_PNG: number = 1
  public static FILE_TYPE_JPG: number = 2
  public static FILE_TYPE_JPEG: number = 3
  public static FILE_TYPE_GIF: number = 4
  public static FILE_TYPE_BMP: number = 5
  public static FILE_TYPE_ICO: number = 6
  public static FILE_TYPE_RAW: number = 7
  public static FILE_TYPE_TIF: number = 8
  public static FILE_TYPE_WEBP: number = 9
  public static FILE_TYPE_HEIC: number = 10
  public static FILE_TYPE_WBMP: number = 12
  public static FILE_TYPE_CR2: number = 13
  public static FILE_TYPE_PSD: number = 14
  private static FIRST_IMAGE_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_PNG
  private static LAST_IMAGE_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_PSD

  /**
   * Video file types
   */
  public static FILE_TYPE_MP4: number = 21
  public static FILE_TYPE_AVI: number = 22
  public static FILE_TYPE_MP2TS: number = 23
  public static FILE_TYPE_MOV: number = 24
  public static FILE_TYPE_RM: number = 25
  public static FILE_TYPE_RMVB: number = 26
  public static FILE_TYPE_FLV: number = 27
  public static FILE_TYPE_MKV: number = 28
  public static FILE_TYPE_M4U: number = 29
  public static FILE_TYPE_WMV: number = 30
  public static FILE_TYPE_ASF: number = 31
  public static FILE_TYPE_RV: number = 32
  public static FILE_TYPE_DIVX: number = 33
  public static FILE_TYPE_3GPP: number = 34
  public static FILE_TYPE_M4V: number = 35
  public static FILE_TYPE_F4V: number = 36
  public static FILE_TYPE_WEBM: number = 37
  public static FILE_TYPE_3GPP2: number = 38
  public static FILE_TYPE_MP2PS: number = 39
  private static FIRST_VIDEO_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_MP4
  private static LAST_VIDEO_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_MP2PS

  /**
   * document file types
   */
  public static FILE_TYPE_MS_WORD: number = 50
  public static FILE_TYPE_MS_POWERPOINT: number = 52
  public static FILE_TYPE_MS_EXCEL: number = 53
  public static FILE_TYPE_PDF: number = 54
  public static FILE_TYPE_HTML: number = 55
  public static FILE_TYPE_XML: number = 56
  public static FILE_TYPE_TEXT: number = 57
  public static FILE_TYPE_MORE_TEXT: number = 58
  private static FIRST_DOC_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_MS_WORD
  private static LAST_DOC_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_MORE_TEXT

  /**
   * Audio file types
   */
  public static FILE_TYPE_MP3: number = 70
  public static FILE_TYPE_WAV: number = 71
  public static FILE_TYPE_AAC: number = 72
  public static FILE_TYPE_RAM: number = 73
  public static FILE_TYPE_APE: number = 74
  public static FILE_TYPE_WMA: number = 75
  public static FILE_TYPE_AU: number = 76
  public static FILE_TYPE_FLAC: number = 77
  public static FILE_TYPE_MP2: number = 78
  public static FILE_TYPE_RA: number = 79
  public static FILE_TYPE_AC3: number = 80
  public static FILE_TYPE_OGG: number = 81
  public static FILE_TYPE_AMR: number = 82
  public static FILE_TYPE_M4A: number = 83
  public static FILE_TYPE_MP4A: number = 84
  public static FILE_TYPE_AIFF: number = 85
  public static FILE_TYPE_MMF: number = 86
  public static FILE_TYPE_AWB: number = 87
  public static FILE_TYPE_MKA: number = 88
  public static FILE_TYPE_QCP: number = 89
  public static FILE_TYPE_MPGA: number = 90
  public static FILE_TYPE_MXMF: number = 91
  public static FILE_TYPE_MID: number = 92
  public static FILE_TYPE_SMF: number = 93
  public static FILE_TYPE_IMY: number = 94
  public static FILE_TYPE_M3U: number = 95
  public static FILE_TYPE_PLS: number = 96
  public static FILE_TYPE_WPL: number = 97
  public static FILE_TYPE_RM_AUDIO: number = 98
  public static FILE_TYPE_MP4_AUDIO: number = 99
  public static FILE_TYPE_3GPP_AUDIO: number = 100
  private static FIRST_AUDIO_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_MP3
  private static LAST_AUDIO_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_3GPP_AUDIO

  /**
   * compressed file types
   */
  public static FILE_TYPE_ZIP: number = 110
  public static FILE_TYPE_RAR: number = 111
  public static FILE_TYPE_JAR: number = 112
  public static FILE_TYPE_GZ: number = 113
  public static FILE_TYPE_TAR: number = 114
  public static FILE_TYPE_Z: number = 115
  public static FILE_TYPE_7Z: number = 116
  public static FILE_TYPE_BZ: number = 117
  public static FILE_TYPE_BZ2: number = 118
  public static FILE_TYPE_TGZ: number = 119
  private static FIRST_COMPRESS_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_ZIP
  private static LAST_COMPRESS_FILE_TYPE: number = FileMimeTypeUtil.FILE_TYPE_TGZ

  /**
   * apk file types
   */
  public static FILE_TYPE_APK: number = 130
  public static FILE_TYPE_HAP: number = 131

  /**
   * vcf file types
   */
  public static FILE_TYPE_VCF: number = 135

  /**
   * 未知类型
   */
  public static FILE_TYPE_UNKNOW: number = 200
  public static SUFFIX_DLP = 'DLP'
  private static UNKNOW_MIMETYPE: MimeType = new MimeType('', MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, '')
  private static fileMimeTypeMap: Map<string, MimeType> = new Map<string, MimeType>()

  addFileMimeType(extension: string, fileCategory: number, fileTypeSort: number,  mimeType: string): void {
    const mType: MimeType = new MimeType(extension, fileCategory, fileTypeSort,  mimeType)
    FileMimeTypeUtil.fileMimeTypeMap.set(extension, mType)
  }

  setFileMimeTypeMap() {
    // 图片
    this.addFileMimeType("PNG", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_PNG, "image/png")
    this.addFileMimeType("WBMP", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_WBMP, "image/vnd.wap.wbmp")
    this.addFileMimeType("BMP", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_BMP, "image/bmp")
    this.addFileMimeType("GIF", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_GIF, "image/gif")
    this.addFileMimeType("JPEG", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_JPEG, "image/jpeg")
    this.addFileMimeType("JPG", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_JPG, "image/jpeg")
    this.addFileMimeType("JPE", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_JPEG, "image/jpeg")
    this.addFileMimeType("CR2", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_CR2, "image/cr2")
    this.addFileMimeType("PSD", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_PSD, "image/psd")
    this.addFileMimeType("HEIC", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_HEIC, "image/heif")
    this.addFileMimeType("HEIF", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_HEIC, "image/heif")
    this.addFileMimeType("DNG", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_RAW, "image/x-adobe-dng")
    this.addFileMimeType("WEBP", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_WEBP, "image/webp")
    this.addFileMimeType("TIF", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_TIF, "image/tiff")
    this.addFileMimeType("ICO", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_ICO, "image/x-icon")
    this.addFileMimeType("ARW", MimeType.FILE_CATEGORY_IMAGE, FileMimeTypeUtil.FILE_TYPE_RAW, "image/x-sony-arw")

    // 视频
    this.addFileMimeType("RMVB", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_RMVB, "video/x-pn-realvideo")
    this.addFileMimeType("M4U", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_M4U, "video/vnd.mpegurl")
    this.addFileMimeType("M4V", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_M4V, "video/x-m4v")
    this.addFileMimeType("MOV", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MOV, "video/quicktime")
    this.addFileMimeType("MP4", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP4, "video/mp4")
    this.addFileMimeType("MPE", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP4, "video/mpeg")
    this.addFileMimeType("MPEG", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP2PS, "video/mpeg")
    this.addFileMimeType("MPG4", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP4, "video/mpeg")
    this.addFileMimeType("MKV", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MKV, "video/x-matroska")
    this.addFileMimeType("WEBM", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_WEBM, "video/x-matroska")
    this.addFileMimeType("3GPP", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_3GPP, "video/3gpp")
    this.addFileMimeType("ASF", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_ASF, "video/x-ms-asf")
    this.addFileMimeType("ASX", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_ASF, "video/x-ms-asf")
    this.addFileMimeType("AVI", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_AVI, "video/x-msvideo")
    this.addFileMimeType("FLV", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_FLV, "video/x-flv")
    this.addFileMimeType("M2TS", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP2PS, "video/mpeg")
    this.addFileMimeType("3G2", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_3GPP2, "video/3gpp2")
    this.addFileMimeType("WMV", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_WMV, "video/x-ms-wmv")
    this.addFileMimeType("MPG", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP4, "video/video/mp2p")
    this.addFileMimeType("3GP", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_3GPP, "video/video/3gpp")
    this.addFileMimeType("RV", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_RV, "video/x-pn-realvideo")
    this.addFileMimeType("TS", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_MP2TS, "video/mp2ts")
    this.addFileMimeType("DIVX", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_DIVX, "video/divx")
    this.addFileMimeType("F4V", MimeType.FILE_CATEGORY_VIDEO, FileMimeTypeUtil.FILE_TYPE_F4V, "video/x-f4v")

    // 文档
    this.addFileMimeType("DOCX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    this.addFileMimeType("DOC", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/msword")
    this.addFileMimeType("DOCM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    this.addFileMimeType("DOTM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    this.addFileMimeType("WPT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/wpt")
    this.addFileMimeType("XLS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.ms-excel")
    this.addFileMimeType("XLSX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    this.addFileMimeType("XLSM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.ms-excel.sheet.macroEnabled.12")
    this.addFileMimeType("XLTM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.ms-excel.template.macroEnabled.12")
    this.addFileMimeType("ET", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/et")
    this.addFileMimeType("PPS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint")
    this.addFileMimeType("PPT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint")
    this.addFileMimeType("PPTX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.openxmlformats-officedocument.presentationml.presentation")
    this.addFileMimeType("PPTM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint.presentation.macroEnabled.12")
    this.addFileMimeType("PPSM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint.slideshow.macroEnabled.12")
    this.addFileMimeType("POTM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint.presentation.macroEnabled.12")
    this.addFileMimeType("DPS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/dps")
    this.addFileMimeType("DPT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/dpt")
    this.addFileMimeType("MSG", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/vnd.ms-outlook")
    this.addFileMimeType("PDF", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_PDF, "application/pdf")
    this.addFileMimeType("RTF", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/rtf")
    this.addFileMimeType("WPS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/vnd.ms-works")
    this.addFileMimeType("XHTML", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "application/xhtml+xml")
    this.addFileMimeType("MPC", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/vnd.mpohun.certificate")
    this.addFileMimeType("JS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "application/x-javascript")
    this.addFileMimeType("C", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("CONF", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("CPP", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("H", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("HTM", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_HTML, "text/html")
    this.addFileMimeType("HTML", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_HTML, "text/html")
    this.addFileMimeType("JAVA", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("LOG", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("PROP", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("RC", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("SH", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("TXT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_TEXT, "text/plain")
    this.addFileMimeType("XML", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_XML, "text/plain")
    this.addFileMimeType("SUB", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/x-subviewer")
    this.addFileMimeType("ASS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/x-ssa")
    this.addFileMimeType("SSA", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/x-ssa")
    this.addFileMimeType("JAD", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/vnd.sun.j2me.app-descriptor")
    this.addFileMimeType("DHTML", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_HTML, "text/html")
    this.addFileMimeType("SHTML", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_HTML, "text/html")
    this.addFileMimeType("TEXT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_TEXT, "text/plain")
    this.addFileMimeType("INI", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/plain")
    this.addFileMimeType("VCS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/x-vcalendar")
    this.addFileMimeType("ICS", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/calendar")
    this.addFileMimeType("JSP", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/html")
    this.addFileMimeType("ASP", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/html")
    this.addFileMimeType("PHP", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MORE_TEXT, "text/html")
    this.addFileMimeType("DOTX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/vnd.openxmlformats-officedocument.wordprocessingml.template")
    this.addFileMimeType("DOT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_WORD, "application/msword")
    this.addFileMimeType("XLT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.ms-excel")
    this.addFileMimeType("XLTX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "application/vnd.openxmlformats-officedocument.spreadsheetml.template")
    this.addFileMimeType("CSV", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_EXCEL, "text/comma-separated-values")
    this.addFileMimeType("POT", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.ms-powerpoint")
    this.addFileMimeType("POTX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.openxmlformats-officedocument.presentationml.template")
    this.addFileMimeType("PPSX", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_MS_POWERPOINT, "application/vnd.openxmlformats-officedocument.presentationml.slideshow")
    this.addFileMimeType("VCF", MimeType.FILE_CATEGORY_TXT, FileMimeTypeUtil.FILE_TYPE_VCF, "text/x-vcard")

    // 音频
    this.addFileMimeType("3GPP2", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_3GPP2, "audio/3gpp2")
    this.addFileMimeType("IMY", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_IMY, "audio/imelody")
    this.addFileMimeType("AAC", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AAC, "audio/aac")
    this.addFileMimeType("AMR", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AMR, "audio/amr")
    this.addFileMimeType("MID", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("MPGA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MPGA, "audio/mpeg")
    this.addFileMimeType("MXMF", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MXMF, "audio/mobile-xmf")
    this.addFileMimeType("RTTTL", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("RTX", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("SMF", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_SMF, "audio/sp-midi")
    this.addFileMimeType("WAV", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_WAV, "audio/x-wav")
    this.addFileMimeType("WMA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_WMA, "audio/x-ms-wma")
    this.addFileMimeType("OTA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("XMF", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("OGG", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_OGG, "audio/ogg")
    this.addFileMimeType("PLS", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_PLS, "audio/x-scpls")
    this.addFileMimeType("RA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_RA, "audio/x-pn-realaudio")
    this.addFileMimeType("RAM", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_RAM, "audio/x-pn-realaudio")
    this.addFileMimeType("MIDI", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MID, "audio/midi")
    this.addFileMimeType("M3U", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_M3U, "audio/x-mpegurl")
    this.addFileMimeType("M4A", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_M4A, "audio/mp4a-latm")
    this.addFileMimeType("M4B", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MP4A, "audio/mp4a-latm")
    this.addFileMimeType("M4P", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MP4A, "audio/mp4a-latm")
    this.addFileMimeType("AWB", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AWB, "audio/amr-wb")
    this.addFileMimeType("MP2", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MP2, "audio/x-mpeg")
    this.addFileMimeType("MP3", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MP3, "audio/x-mpeg")
    this.addFileMimeType("AU", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AU, "audio/basic")
    this.addFileMimeType("OGA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_OGG, "application/ogg")
    this.addFileMimeType("WPL", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_WPL, "application/vnd.ms-wpl")
    this.addFileMimeType("AC3", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AC3, "audio/ac3")
    this.addFileMimeType("MKA", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_MKA, "audio/x-matroska")
    this.addFileMimeType("FLAC", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_FLAC, "audio/flac")
    this.addFileMimeType("AIF", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AIFF, "audio/x-aiff")
    this.addFileMimeType("AIFF", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AIFF, "audio/x-aiff")
    this.addFileMimeType("AIFC", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_AIFF, "audio/x-aiff")
    this.addFileMimeType("APE", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_APE, "audio/x-ape")
    this.addFileMimeType("RM", MimeType.FILE_CATEGORY_AUDIO, FileMimeTypeUtil.FILE_TYPE_RM_AUDIO, "audio/x-pn-realaudio")

    // 压缩包
    this.addFileMimeType("GTAR", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_ZIP, "application/x-gtar")
    this.addFileMimeType("RAR", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_RAR, "application/x-rar-compressed")
    this.addFileMimeType("TAR", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_TAR, "application/x-tar")
    this.addFileMimeType("TGZ", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_TGZ, "application/x-compressed")
    this.addFileMimeType("Z", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_Z, "application/x-compressed")
    this.addFileMimeType("ZIP", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_ZIP, "application/zip")
    this.addFileMimeType("JAR", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_JAR, "text/vnd.sun.j2me.app-descriptor")
    this.addFileMimeType("GZ", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_GZ, "application/x-gzip")
    this.addFileMimeType("BZ", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_BZ, "application/x-bzip")
    this.addFileMimeType("BZ2", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_BZ2, "application/x-bzip2")
    this.addFileMimeType("7Z", MimeType.FILE_CATEGORY_ZIP, FileMimeTypeUtil.FILE_TYPE_7Z, "application/x-7z-compressed")

    // 安装包
    this.addFileMimeType("APK", MimeType.FILE_CATEGORY_PKG, FileMimeTypeUtil.FILE_TYPE_APK, "application/vnd.android.package-archive")
    this.addFileMimeType("HAP", MimeType.FILE_CATEGORY_PKG, FileMimeTypeUtil.FILE_TYPE_HAP, "file/*")

    // 未知
    this.addFileMimeType("EXE", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("BIN", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("CLASS", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("RAW", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("EPUB", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/epub+zip")
    this.addFileMimeType("EBK3", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-expandedbook")
    this.addFileMimeType("SAMI", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-sami")
    this.addFileMimeType("SMI", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-sami")
    this.addFileMimeType("STR", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-subrip")
    this.addFileMimeType("SWF", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-shockwave-flash")
    this.addFileMimeType("CAB", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-shockwave-flash")
    this.addFileMimeType("CHM", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/x-chm")
    this.addFileMimeType("UMD", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/umd")
    this.addFileMimeType("PDB", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/ebook")
    this.addFileMimeType("DCF", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/vnd.oma.drm.content")
    this.addFileMimeType("K3G", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("MPO", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_UNKNOW, "application/octet-stream")
    this.addFileMimeType("MMF", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_MMF, "application/vnd.smaf")
    this.addFileMimeType("QCP", MimeType.FILE_CATEGORY_UNKNOW, FileMimeTypeUtil.FILE_TYPE_QCP, "application/octet-stream")
  }

  getFileMiMeTypeMap(): Map<string, MimeType> {
    if (FileMimeTypeUtil.fileMimeTypeMap.size === 0) {
      this.setFileMimeTypeMap()
    }
    return FileMimeTypeUtil.fileMimeTypeMap
  }

  getFileMimeType(fileName: string): MimeType {
    if (StringUtil.isEmpty(fileName)) {
      return FileMimeTypeUtil.UNKNOW_MIMETYPE
    }

    const splitList = fileName.split('.')
    if (splitList.length < 2) {
      return FileMimeTypeUtil.UNKNOW_MIMETYPE
    }

    let suffix = splitList[splitList.length-1].toUpperCase()
    // 判断DLP加密文件
    if (suffix === FileMimeTypeUtil.SUFFIX_DLP) {
      if (splitList.length === 2) {
        return FileMimeTypeUtil.UNKNOW_MIMETYPE
      }
      suffix = splitList[splitList.length-2].toUpperCase()
    }
    const fileMiMeTypeMap = this.getFileMiMeTypeMap()
    const mimeType: MimeType | undefined = fileMiMeTypeMap.get(suffix)
    if (!mimeType) {
      return FileMimeTypeUtil.UNKNOW_MIMETYPE
    }
    return mimeType
  }

  getFileSuffix(fileName: string): String {
    const unKnown: string = '';
    if (StringUtil.isEmpty(fileName)) {
      return unKnown;
    }

    const splitList = fileName.split('.')
    if (splitList.length < 2) {
      return unKnown;
    }

    let suffix = splitList[splitList.length-1].toUpperCase()
    // 判断DLP加密文件
    if (suffix === FileMimeTypeUtil.SUFFIX_DLP) {
      if (splitList.length === 2) {
        return unKnown;
      }
      suffix = splitList[splitList.length-2].toUpperCase()
    }
    return suffix
  }

  getFileTypeOrder(fileName: string): number {
    const mimeType = this.getFileMimeType(fileName)
    return mimeType.getFileTypeSort()
  }
}

export default FileMimeTypeUtil


