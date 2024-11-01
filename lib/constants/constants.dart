enum SupportedFileType{
  pdf(type:"pdf"),
  txt(type:"txt"),
  doc(type:"doc"),
  docx(type:"docx"),
  xls(type:"xls"),
  xlsx(type:"xlsx"),
  ppt(type:"ppt"),
  pptx(type:"pptx"),
  epub(type:"epub"),
  mobi(type:"mobi"),
  html(type:"html"),
  htm(type:"htm");

  final String type;
  const SupportedFileType({required this.type});

  static SupportedFileType toEnum(String type) {
    return SupportedFileType.values.firstWhere((fileType) => fileType.type == type,
      orElse: () => SupportedFileType.doc, // Returns null if no match is found
    );
  }
}

class Constants{
  static const String SHELF_ID_PREFIX='SID';
  static const String FILE_ID_PREFIX='FID';
  static const int DEFAULT_PAGE_SIZE = 40;
  static final _SVG_FILE_PATH= Map<SupportedFileType,String>.fromEntries([
        const MapEntry(SupportedFileType.txt,'assets/svg/txt.svg'),
        const MapEntry(SupportedFileType.doc,'assets/svg/doc.svg'),
        const MapEntry(SupportedFileType.docx,'assets/svg/doc.svg'),
        const MapEntry(SupportedFileType.xls,'assets/svg/xlsx.svg'),
        const MapEntry(SupportedFileType.xlsx,'assets/svg/xlsx.svg'),
        const MapEntry(SupportedFileType.ppt,'assets/svg/ppt.svg'),
        const MapEntry(SupportedFileType.pptx,'assets/svg/pptx.svg'),
        const MapEntry(SupportedFileType.pdf,'assets/svg/pdf.svg'),
        const MapEntry(SupportedFileType.epub,'assets/svg/doc.svg'),
        const MapEntry(SupportedFileType.mobi,'assets/svg/doc.svg'),
        const MapEntry(SupportedFileType.html,'assets/svg/html.svg'),
        const MapEntry(SupportedFileType.htm,'assets/svg/html.svg'),
  ]);

  static getFileSvgPath(SupportedFileType fileType){
    return _SVG_FILE_PATH.containsKey(fileType) ? _SVG_FILE_PATH[fileType] : _SVG_FILE_PATH[SupportedFileType.doc];
  }
}