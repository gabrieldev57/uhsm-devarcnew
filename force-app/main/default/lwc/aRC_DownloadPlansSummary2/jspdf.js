import { saveAs } from "./libs/FileSaver.js";

import { globalObject } from "./libs/globalObject.js";
import { RGBColor } from "./libs/rgbcolor.js";
import { btoa } from "./libs/AtobBtoa.js";
import { console } from "./libs/console.js";
import { PDFSecurity } from "./libs/pdfsecurity.js";
import { toPDFName } from "./libs/pdfname.js";

import { addImage } from './addImage';

function PubSub(context) {
  if (typeof context !== "object") {
    throw new Error(
      "Invalid Context passed to initialize PubSub (jsPDF-module)"
    );
  }
  var topics = {};

  this.subscribe = function(topic, callback, once) {
    once = once || false;
    if (
      typeof topic !== "string" ||
      typeof callback !== "function" ||
      typeof once !== "boolean"
    ) {
      throw new Error(
        "Invalid arguments passed to PubSub.subscribe (jsPDF-module)"
      );
    }

    if (!topics.hasOwnProperty(topic)) {
      topics[topic] = {};
    }

    var token = Math.random().toString(35);
    topics[topic][token] = [callback, !!once];

    return token;
  };

  this.unsubscribe = function(token) {
    for (var topic in topics) {
      if (topics[topic][token]) {
        delete topics[topic][token];
        if (Object.keys(topics[topic]).length === 0) {
          delete topics[topic];
        }
        return true;
      }
    }
    return false;
  };

  this.publish = function(topic) {
    if (topics.hasOwnProperty(topic)) {
      var args = Array.prototype.slice.call(arguments, 1),
        tokens = [];

      for (var token in topics[topic]) {
        var sub = topics[topic][token];
        try {
          sub[0].apply(context, args);
        } catch (ex) {
          if (globalObject.console) {
            console.error("jsPDF PubSub Error", ex.message, ex);
          }
        }
        if (sub[1]) tokens.push(token);
      }
      if (tokens.length) tokens.forEach(this.unsubscribe);
    }
  };

  this.getTopics = function() {
    return topics;
  };
}

function GState(parameters) {
  if (!(this instanceof GState)) {
    return new GState(parameters);
  }

  var supported = "opacity,stroke-opacity".split(",");
  for (var p in parameters) {
    if (parameters.hasOwnProperty(p) && supported.indexOf(p) >= 0) {
      this[p] = parameters[p];
    }
  }
  this.id = "";
  this.objectNumber = -1;
}
GState.prototype.equals = function equals(other) {
  var ignore = "id,objectNumber,equals";
  var p;
  if (!other || typeof other !== typeof this) return false;
  var count = 0;
  for (p in this) {
    if (ignore.indexOf(p) >= 0) continue;
    if (this.hasOwnProperty(p) && !other.hasOwnProperty(p)) return false;
    if (this[p] !== other[p]) return false;
    count++;
  }
  for (p in other) {
    if (other.hasOwnProperty(p) && ignore.indexOf(p) < 0) count--;
  }
  return count === 0;
};

function Pattern(gState, matrix) {
  this.gState = gState;
  this.matrix = matrix;

  this.id = "";
  this.objectNumber = -1;
}
function ShadingPattern(type, coords, colors, gState, matrix) {
  if (!(this instanceof ShadingPattern)) {
    return new ShadingPattern(type, coords, colors, gState, matrix);
  }
  this.type = type === "axial" ? 2 : 3;
  this.coords = coords;
  this.colors = colors;

  Pattern.call(this, gState, matrix);
}

function TilingPattern(boundingBox, xStep, yStep, gState, matrix) {
  if (!(this instanceof TilingPattern)) {
    return new TilingPattern(boundingBox, xStep, yStep, gState, matrix);
  }

  this.boundingBox = boundingBox;
  this.xStep = xStep;
  this.yStep = yStep;

  this.stream = "";

  this.cloneIndex = 0;

  Pattern.call(this, gState, matrix);
}
function jsPDF(options) {
  var orientation = typeof arguments[0] === "string" ? arguments[0] : "p";
  var unit = arguments[1];
  var format = arguments[2];
  var compressPdf = arguments[3];
  var filters = [];
  var userUnit = 1.0;
  var precision;
  var floatPrecision = 16;
  var defaultPathOperation = "S";
  var encryptionOptions = null;
  options = options || {};
  if (typeof options === "object") {
    orientation = options.orientation;
    unit = options.unit || unit;
    format = options.format || format;
    compressPdf = options.compress || options.compressPdf || compressPdf;
    encryptionOptions = options.encryption || null;
    if (encryptionOptions !== null) {
      encryptionOptions.userPassword = encryptionOptions.userPassword || "";
      encryptionOptions.ownerPassword = encryptionOptions.ownerPassword || "";
      encryptionOptions.userPermissions =
        encryptionOptions.userPermissions || [];
    }
    userUnit =
      typeof options.userUnit === "number" ? Math.abs(options.userUnit) : 1.0;
    if (typeof options.precision !== "undefined") {
      precision = options.precision;
    }
    if (typeof options.floatPrecision !== "undefined") {
      floatPrecision = options.floatPrecision;
    }
    defaultPathOperation = options.defaultPathOperation || "S";
  }
  filters =
    options.filters || (compressPdf === true ? ["FlateEncode"] : filters);
  unit = unit || "mm";
  orientation = ("" + (orientation || "P")).toLowerCase();
  var putOnlyUsedFonts = options.putOnlyUsedFonts || false;
  var usedFonts = {};

  var API = {
    internal: {},
    __private__: {}
  };
  API.__private__.PubSub = PubSub;
  var pdfVersion = "1.3";
  var getPdfVersion = (API.__private__.getPdfVersion = function() {
    return pdfVersion;
  });
  API.__private__.setPdfVersion = function(value) {
    pdfVersion = value;
  };
  var pageFormats = {
    a0: [2383.94, 3370.39],
    a1: [1683.78, 2383.94],
    a2: [1190.55, 1683.78],
    a3: [841.89, 1190.55],
    a4: [595.28, 841.89],
    a5: [419.53, 595.28],
    a6: [297.64, 419.53],
    a7: [209.76, 297.64],
    a8: [147.4, 209.76],
    a9: [104.88, 147.4],
    a10: [73.7, 104.88],
    b0: [2834.65, 4008.19],
    b1: [2004.09, 2834.65],
    b2: [1417.32, 2004.09],
    b3: [1000.63, 1417.32],
    b4: [708.66, 1000.63],
    b5: [498.9, 708.66],
    b6: [354.33, 498.9],
    b7: [249.45, 354.33],
    b8: [175.75, 249.45],
    b9: [124.72, 175.75],
    b10: [87.87, 124.72],
    c0: [2599.37, 3676.54],
    c1: [1836.85, 2599.37],
    c2: [1298.27, 1836.85],
    c3: [918.43, 1298.27],
    c4: [649.13, 918.43],
    c5: [459.21, 649.13],
    c6: [323.15, 459.21],
    c7: [229.61, 323.15],
    c8: [161.57, 229.61],
    c9: [113.39, 161.57],
    c10: [79.37, 113.39],
    dl: [311.81, 623.62],
    letter: [612, 792],
    "government-letter": [576, 756],
    legal: [612, 1008],
    "junior-legal": [576, 360],
    ledger: [1224, 792],
    tabloid: [792, 1224],
    "credit-card": [153, 243]
  };
  API.__private__.getPageFormats = function() {
    return pageFormats;
  };
  var getPageFormat = (API.__private__.getPageFormat = function(value) {
    return pageFormats[value];
  });
  format = format || "a4";
  var ApiMode = {
    COMPAT: "compat",
    ADVANCED: "advanced"
  };
  var apiMode = ApiMode.COMPAT;

  function advancedAPI() {
    this.saveGraphicsState();
    out(
      new Matrix(
        scaleFactor,
        0,
        0,
        -scaleFactor,
        0,
        getPageHeight() * scaleFactor
      ).toString() + " cm"
    );
    this.setFontSize(this.getFontSize() / scaleFactor);

    defaultPathOperation = "n";

    apiMode = ApiMode.ADVANCED;
  }

  function compatAPI() {
    this.restoreGraphicsState();
    defaultPathOperation = "S";
    apiMode = ApiMode.COMPAT;
  }

  var combineFontStyleAndFontWeight = (API.__private__.combineFontStyleAndFontWeight = function(
    fontStyle,
    fontWeight
  ) {
    if (
      (fontStyle == "bold" && fontWeight == "normal") ||
      (fontStyle == "bold" && fontWeight == 400) ||
      (fontStyle == "normal" && fontWeight == "italic") ||
      (fontStyle == "bold" && fontWeight == "italic")
    ) {
      throw new Error("Invalid Combination of fontweight and fontstyle");
    }
    if (fontWeight) {
      fontStyle =
        fontWeight == 400 || fontWeight === "normal"
          ? fontStyle === "italic"
            ? "italic"
            : "normal"
          : (fontWeight == 700 || fontWeight === "bold") &&
            fontStyle === "normal"
          ? "bold"
          : (fontWeight == 700 ? "bold" : fontWeight) + "" + fontStyle;
    }
    return fontStyle;
  });

  API.advancedAPI = function(body) {
    var doSwitch = apiMode === ApiMode.COMPAT;

    if (doSwitch) {
      advancedAPI.call(this);
    }

    if (typeof body !== "function") {
      return this;
    }

    body(this);

    if (doSwitch) {
      compatAPI.call(this);
    }

    return this;
  };


  API.compatAPI = function(body) {
    var doSwitch = apiMode === ApiMode.ADVANCED;

    if (doSwitch) {
      compatAPI.call(this);
    }

    if (typeof body !== "function") {
      return this;
    }

    body(this);

    if (doSwitch) {
      advancedAPI.call(this);
    }

    return this;
  };


  API.isAdvancedAPI = function() {
    return apiMode === ApiMode.ADVANCED;
  };

  var advancedApiModeTrap = function(methodName) {
    if (apiMode !== ApiMode.ADVANCED) {
      throw new Error(
        methodName +
          " is only available in 'advanced' API mode. " +
          "You need to call advancedAPI() first."
      );
    }
  };

  var roundToPrecision = (API.roundToPrecision = API.__private__.roundToPrecision = function(
    number,
    parmPrecision
  ) {
    var tmpPrecision = precision || parmPrecision;
    if (isNaN(number) || isNaN(tmpPrecision)) {
      throw new Error("Invalid argument passed to jsPDF.roundToPrecision");
    }
    return number.toFixed(tmpPrecision).replace(/0+$/, "");
  });
  var hpf;
  if (typeof floatPrecision === "number") {
    hpf = API.hpf = API.__private__.hpf = function(number) {
      if (isNaN(number)) {
        throw new Error("Invalid argument passed to jsPDF.hpf");
      }
      return roundToPrecision(number, floatPrecision);
    };
  } else if (floatPrecision === "smart") {
    hpf = API.hpf = API.__private__.hpf = function(number) {
      if (isNaN(number)) {
        throw new Error("Invalid argument passed to jsPDF.hpf");
      }
      if (number > -1 && number < 1) {
        return roundToPrecision(number, 16);
      } else {
        return roundToPrecision(number, 5);
      }
    };
  } else {
    hpf = API.hpf = API.__private__.hpf = function(number) {
      if (isNaN(number)) {
        throw new Error("Invalid argument passed to jsPDF.hpf");
      }
      return roundToPrecision(number, 16);
    };
  }
  var f2 = (API.f2 = API.__private__.f2 = function(number) {
    if (isNaN(number)) {
      throw new Error("Invalid argument passed to jsPDF.f2");
    }
    return roundToPrecision(number, 2);
  });

  var f3 = (API.__private__.f3 = function(number) {
    if (isNaN(number)) {
      throw new Error("Invalid argument passed to jsPDF.f3");
    }
    return roundToPrecision(number, 3);
  });
  var scale = (API.scale = API.__private__.scale = function(number) {
    if (isNaN(number)) {
      throw new Error("Invalid argument passed to jsPDF.scale");
    }
    if (apiMode === ApiMode.COMPAT) {
      return number * scaleFactor;
    } else if (apiMode === ApiMode.ADVANCED) {
      return number;
    }
  });
  var transformY = function(y) {
    if (apiMode === ApiMode.COMPAT) {
      return getPageHeight() - y;
    } else if (apiMode === ApiMode.ADVANCED) {
      return y;
    }
  };
  var transformScaleY = function(y) {
    return scale(transformY(y));
  };
  API.__private__.setPrecision = API.setPrecision = function(value) {
    if (typeof parseInt(value, 10) === "number") {
      precision = parseInt(value, 10);
    }
  };
  var fileId = "00000000000000000000000000000000";

  var getFileId = (API.__private__.getFileId = function() {
    return fileId;
  });
  var setFileId = (API.__private__.setFileId = function(value) {
    if (typeof value !== "undefined" && /^[a-fA-F0-9]{32}$/.test(value)) {
      fileId = value.toUpperCase();
    } else {
      fileId = fileId
        .split("")
        .map(function() {
          return "ABCDEF0123456789".charAt(Math.floor(Math.random() * 16));
        })
        .join("");
    }
    if (encryptionOptions !== null) {
      encryption = new PDFSecurity(
        encryptionOptions.userPermissions,
        encryptionOptions.userPassword,
        encryptionOptions.ownerPassword,
        fileId
      );
    }
    return fileId;
  });
  API.setFileId = function(value) {
    setFileId(value);
    return this;
  };
  API.getFileId = function() {
    return getFileId();
  };
  var creationDate;
  var convertDateToPDFDate = (API.__private__.convertDateToPDFDate = function(
    parmDate
  ) {
    var result = "";
    var tzoffset = parmDate.getTimezoneOffset(),
      tzsign = tzoffset < 0 ? "+" : "-",
      tzhour = Math.floor(Math.abs(tzoffset / 60)),
      tzmin = Math.abs(tzoffset % 60),
      timeZoneString = [tzsign, padd2(tzhour), "'", padd2(tzmin), "'"].join("");

    result = [
      "D:",
      parmDate.getFullYear(),
      padd2(parmDate.getMonth() + 1),
      padd2(parmDate.getDate()),
      padd2(parmDate.getHours()),
      padd2(parmDate.getMinutes()),
      padd2(parmDate.getSeconds()),
      timeZoneString
    ].join("");
    return result;
  });

  var convertPDFDateToDate = (API.__private__.convertPDFDateToDate = function(
    parmPDFDate
  ) {
    var year = parseInt(parmPDFDate.substr(2, 4), 10);
    var month = parseInt(parmPDFDate.substr(6, 2), 10) - 1;
    var date = parseInt(parmPDFDate.substr(8, 2), 10);
    var hour = parseInt(parmPDFDate.substr(10, 2), 10);
    var minutes = parseInt(parmPDFDate.substr(12, 2), 10);
    var seconds = parseInt(parmPDFDate.substr(14, 2), 10);

    var resultingDate = new Date(year, month, date, hour, minutes, seconds, 0);
    return resultingDate;
  });

  var setCreationDate = (API.__private__.setCreationDate = function(date) {
    var tmpCreationDateString;
    var regexPDFCreationDate = /^D:(20[0-2][0-9]|203[0-7]|19[7-9][0-9])(0[0-9]|1[0-2])([0-2][0-9]|3[0-1])(0[0-9]|1[0-9]|2[0-3])(0[0-9]|[1-5][0-9])(0[0-9]|[1-5][0-9])(\+0[0-9]|\+1[0-4]|-0[0-9]|-1[0-1])'(0[0-9]|[1-5][0-9])'?$/;
    if (typeof date === "undefined") {
      date = new Date();
    }
    if (date instanceof Date) {
      tmpCreationDateString = convertDateToPDFDate(date);
    } else if (regexPDFCreationDate.test(date)) {
      tmpCreationDateString = date;
    } else {
      throw new Error("Invalid argument passed to jsPDF.setCreationDate");
    }
    creationDate = tmpCreationDateString;
    return creationDate;
  });
  var getCreationDate = (API.__private__.getCreationDate = function(type) {
    var result = creationDate;
    if (type === "jsDate") {
      result = convertPDFDateToDate(creationDate);
    }
    return result;
  });
  API.setCreationDate = function(date) {
    setCreationDate(date);
    return this;
  };
  API.getCreationDate = function(type) {
    return getCreationDate(type);
  };
  var padd2 = (API.__private__.padd2 = function(number) {
    return ("0" + parseInt(number)).slice(-2);
  });
  var padd2Hex = (API.__private__.padd2Hex = function(hexString) {
    hexString = hexString.toString();
    return ("00" + hexString).substr(hexString.length);
  });
  var objectNumber = 0;
  var offsets = [];
  var content = [];
  var contentLength = 0;
  var additionalObjects = [];

  var pages = [];
  var currentPage;
  var hasCustomDestination = false;
  var outputDestination = content;

  var resetDocument = function() {
    objectNumber = 0;
    contentLength = 0;
    content = [];
    offsets = [];
    additionalObjects = [];

    rootDictionaryObjId = newObjectDeferred();
    resourceDictionaryObjId = newObjectDeferred();
  };
  API.__private__.setCustomOutputDestination = function(destination) {
    hasCustomDestination = true;
    outputDestination = destination;
  };
  var setOutputDestination = function(destination) {
    if (!hasCustomDestination) {
      outputDestination = destination;
    }
  };
  API.__private__.resetCustomOutputDestination = function() {
    hasCustomDestination = false;
    outputDestination = content;
  };
  var out = (API.__private__.out = function(string) {
    string = string.toString();
    contentLength += string.length + 1;
    outputDestination.push(string);
    return outputDestination;
  });
  var write = (API.__private__.write = function(value) {
    return out(
      arguments.length === 1
        ? value.toString()
        : Array.prototype.join.call(arguments, " ")
    );
  });
  var getArrayBuffer = (API.__private__.getArrayBuffer = function(data) {
    var len = data.length,
      ab = new ArrayBuffer(len),
      u8 = new Uint8Array(ab);
    while (len--) u8[len] = data.charCodeAt(len);
    return ab;
  });
  var standardFonts = [
    ["Helvetica", "helvetica", "normal", "WinAnsiEncoding"],
    ["Helvetica-Bold", "helvetica", "bold", "WinAnsiEncoding"],
    ["Helvetica-Oblique", "helvetica", "italic", "WinAnsiEncoding"],
    ["Helvetica-BoldOblique", "helvetica", "bolditalic", "WinAnsiEncoding"],
    ["Courier", "courier", "normal", "WinAnsiEncoding"],
    ["Courier-Bold", "courier", "bold", "WinAnsiEncoding"],
    ["Courier-Oblique", "courier", "italic", "WinAnsiEncoding"],
    ["Courier-BoldOblique", "courier", "bolditalic", "WinAnsiEncoding"],
    ["Times-Roman", "times", "normal", "WinAnsiEncoding"],
    ["Times-Bold", "times", "bold", "WinAnsiEncoding"],
    ["Times-Italic", "times", "italic", "WinAnsiEncoding"],
    ["Times-BoldItalic", "times", "bolditalic", "WinAnsiEncoding"],
    ["ZapfDingbats", "zapfdingbats", "normal", null],
    ["Symbol", "symbol", "normal", null]
  ];

  API.__private__.getStandardFonts = function() {
    return standardFonts;
  };
  var activeFontSize = options.fontSize || 16;
  API.__private__.setFontSize = API.setFontSize = function(size) {
    if (apiMode === ApiMode.ADVANCED) {
      activeFontSize = size / scaleFactor;
    } else {
      activeFontSize = size;
    }
    return this;
  };
  var getFontSize = (API.__private__.getFontSize = API.getFontSize = function() {
    if (apiMode === ApiMode.COMPAT) {
      return activeFontSize;
    } else {
      return activeFontSize * scaleFactor;
    }
  });
  var R2L = options.R2L || false;
  API.__private__.setR2L = API.setR2L = function(value) {
    R2L = value;
    return this;
  };
  API.__private__.getR2L = API.getR2L = function() {
    return R2L;
  };
  var zoomMode;
  var setZoomMode = (API.__private__.setZoomMode = function(zoom) {
    var validZoomModes = [
      undefined,
      null,
      "fullwidth",
      "fullheight",
      "fullpage",
      "original"
    ];
    if (/^\d*\.?\d*%$/.test(zoom)) {
      zoomMode = zoom;
    } else if (!isNaN(zoom)) {
      zoomMode = parseInt(zoom, 10);
    } else if (validZoomModes.indexOf(zoom) !== -1) {
      zoomMode = zoom;
    } else {
      throw new Error(
        'zoom must be Integer (e.g. 2), a percentage Value (e.g. 300%) or fullwidth, fullheight, fullpage, original. "' +
          zoom +
          '" is not recognized.'
      );
    }
  });

  var getImageDataFromElement = function getImageDataFromElement(element, format) {
    console.log('entro a getImageDataFromElement');
    //if element is an image which uses data url definition, just return the dataurl
    // if (element.nodeName === "IMG" && element.hasAttribute("src")) {
    var src = "" + element.getAttribute("src"); //is base64 encoded dataUrl, directly process it

    if (src.indexOf("data:image/") === 0) {
        return atob(unescape(src).split("base64,").pop());
    } //it is probably an url, try to load it


    var tmpImageData = API.loadFile(src, true);

    if (tmpImageData !== undefined) {
        return tmpImageData;
    }
    // }

    // if (element.nodeName === "CANVAS") {
    // if (element.width === 0 || element.height === 0) {
    //     throw new Error("Given canvas must have data. Canvas width: " + element.width + ", height: " + element.height);
    // }

    // var mimeType;

    // switch (format) {
    //     case "PNG":
    //     mimeType = "image/png";
    //     break;

    //     case "WEBP":
    //     mimeType = "image/webp";
    //     break;

    //     case "JPEG":
    //     case "JPG":
    //     default:
    //     mimeType = "image/jpeg";
    //     break;
    // }

    // return atob(element.toDataURL(mimeType, 1.0).split("base64,").pop());
    // }
};
  API.__private__.getZoomMode = function() {
    return zoomMode;
  };

  var pageMode;
  var setPageMode = (API.__private__.setPageMode = function(pmode) {
    var validPageModes = [
      undefined,
      null,
      "UseNone",
      "UseOutlines",
      "UseThumbs",
      "FullScreen"
    ];
    if (validPageModes.indexOf(pmode) == -1) {
      throw new Error(
        'Page mode must be one of UseNone, UseOutlines, UseThumbs, or FullScreen. "' +
          pmode +
          '" is not recognized.'
      );
    }
    pageMode = pmode;
  });
  API.__private__.getPageMode = function() {
    return pageMode;
  };
  var layoutMode;
  var setLayoutMode = (API.__private__.setLayoutMode = function(layout) {
    var validLayoutModes = [
      undefined,
      null,
      "continuous",
      "single",
      "twoleft",
      "tworight",
      "two"
    ];
    if (validLayoutModes.indexOf(layout) == -1) {
      throw new Error(
        'Layout mode must be one of continuous, single, twoleft, tworight. "' +
          layout +
          '" is not recognized.'
      );
    }
    layoutMode = layout;
  });
  API.__private__.getLayoutMode = function() {
    return layoutMode;
  };
  API.__private__.setDisplayMode = API.setDisplayMode = function(
    zoom,
    layout,
    pmode
  ) {
    setZoomMode(zoom);
    setLayoutMode(layout);
    setPageMode(pmode);
    return this;
  };
  var documentProperties = {
    title: "",
    subject: "",
    author: "",
    keywords: "",
    creator: ""
  };
  API.__private__.getDocumentProperty = function(key) {
    if (Object.keys(documentProperties).indexOf(key) === -1) {
      throw new Error("Invalid argument passed to jsPDF.getDocumentProperty");
    }
    return documentProperties[key];
  };

  API.__private__.getDocumentProperties = function() {
    return documentProperties;
  };

  API.__private__.setDocumentProperties = API.setProperties = API.setDocumentProperties = function(
    properties
  ) {
    for (var property in documentProperties) {
      if (documentProperties.hasOwnProperty(property) && properties[property]) {
        documentProperties[property] = properties[property];
      }
    }
    return this;
  };
  API.__private__.setDocumentProperty = function(key, value) {
    if (Object.keys(documentProperties).indexOf(key) === -1) {
      throw new Error("Invalid arguments passed to jsPDF.setDocumentProperty");
    }
    return (documentProperties[key] = value);
  };
  var fonts = {};
  var fontmap = {};
  var activeFontKey;
  var fontStateStack = [];
  var patterns = {};
  var patternMap = {};
  var gStates = {};
  var gStatesMap = {};
  var activeGState = null;
  var scaleFactor;
  var page = 0;
  var pagesContext = [];
  var events = new PubSub(API);
  var hotfixes = options.hotfixes || [];

  var renderTargets = {};
  var renderTargetMap = {};
  var renderTargetStack = [];
  var pageX;
  var pageY;
  var pageMatrix;

  var Matrix = function(sx, shy, shx, sy, tx, ty) {
    if (!(this instanceof Matrix)) {
      return new Matrix(sx, shy, shx, sy, tx, ty);
    }
    if (isNaN(sx)) sx = 1;
    if (isNaN(shy)) shy = 0;
    if (isNaN(shx)) shx = 0;
    if (isNaN(sy)) sy = 1;
    if (isNaN(tx)) tx = 0;
    if (isNaN(ty)) ty = 0;
    this._matrix = [sx, shy, shx, sy, tx, ty];
  };
  Object.defineProperty(Matrix.prototype, "sx", {
    get: function() {
      return this._matrix[0];
    },
    set: function(value) {
      this._matrix[0] = value;
    }
  });
  Object.defineProperty(Matrix.prototype, "shy", {
    get: function() {
      return this._matrix[1];
    },
    set: function(value) {
      this._matrix[1] = value;
    }
  });
  Object.defineProperty(Matrix.prototype, "shx", {
    get: function() {
      return this._matrix[2];
    },
    set: function(value) {
      this._matrix[2] = value;
    }
  });
  Object.defineProperty(Matrix.prototype, "sy", {
    get: function() {
      return this._matrix[3];
    },
    set: function(value) {
      this._matrix[3] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "tx", {
    get: function() {
      return this._matrix[4];
    },
    set: function(value) {
      this._matrix[4] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "ty", {
    get: function() {
      return this._matrix[5];
    },
    set: function(value) {
      this._matrix[5] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "a", {
    get: function() {
      return this._matrix[0];
    },
    set: function(value) {
      this._matrix[0] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "b", {
    get: function() {
      return this._matrix[1];
    },
    set: function(value) {
      this._matrix[1] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "c", {
    get: function() {
      return this._matrix[2];
    },
    set: function(value) {
      this._matrix[2] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "d", {
    get: function() {
      return this._matrix[3];
    },
    set: function(value) {
      this._matrix[3] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "e", {
    get: function() {
      return this._matrix[4];
    },
    set: function(value) {
      this._matrix[4] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "f", {
    get: function() {
      return this._matrix[5];
    },
    set: function(value) {
      this._matrix[5] = value;
    }
  });

  Object.defineProperty(Matrix.prototype, "rotation", {
    get: function() {
      return Math.atan2(this.shx, this.sx);
    }
  });

  Object.defineProperty(Matrix.prototype, "scaleX", {
    get: function() {
      return this.decompose().scale.sx;
    }
  });

  Object.defineProperty(Matrix.prototype, "scaleY", {
    get: function() {
      return this.decompose().scale.sy;
    }
  });

  Object.defineProperty(Matrix.prototype, "isIdentity", {
    get: function() {
      if (this.sx !== 1) {
        return false;
      }
      if (this.shy !== 0) {
        return false;
      }
      if (this.shx !== 0) {
        return false;
      }
      if (this.sy !== 1) {
        return false;
      }
      if (this.tx !== 0) {
        return false;
      }
      if (this.ty !== 0) {
        return false;
      }
      return true;
    }
  });

  Matrix.prototype.join = function(separator) {
    return [this.sx, this.shy, this.shx, this.sy, this.tx, this.ty]
      .map(hpf)
      .join(separator);
  };

  Matrix.prototype.multiply = function(matrix) {
    var sx = matrix.sx * this.sx + matrix.shy * this.shx;
    var shy = matrix.sx * this.shy + matrix.shy * this.sy;
    var shx = matrix.shx * this.sx + matrix.sy * this.shx;
    var sy = matrix.shx * this.shy + matrix.sy * this.sy;
    var tx = matrix.tx * this.sx + matrix.ty * this.shx + this.tx;
    var ty = matrix.tx * this.shy + matrix.ty * this.sy + this.ty;

    return new Matrix(sx, shy, shx, sy, tx, ty);
  };

  Matrix.prototype.decompose = function() {
    var a = this.sx;
    var b = this.shy;
    var c = this.shx;
    var d = this.sy;
    var e = this.tx;
    var f = this.ty;

    var scaleX = Math.sqrt(a * a + b * b);
    a /= scaleX;
    b /= scaleX;

    var shear = a * c + b * d;
    c -= a * shear;
    d -= b * shear;

    var scaleY = Math.sqrt(c * c + d * d);
    c /= scaleY;
    d /= scaleY;
    shear /= scaleY;

    if (a * d < b * c) {
      a = -a;
      b = -b;
      shear = -shear;
      scaleX = -scaleX;
    }

    return {
      scale: new Matrix(scaleX, 0, 0, scaleY, 0, 0),
      translate: new Matrix(1, 0, 0, 1, e, f),
      rotate: new Matrix(a, b, -b, a, 0, 0),
      skew: new Matrix(1, 0, shear, 1, 0, 0)
    };
  };

  Matrix.prototype.toString = function(parmPrecision) {
    return this.join(" ");
  };

  Matrix.prototype.inversed = function() {
    var a = this.sx,
      b = this.shy,
      c = this.shx,
      d = this.sy,
      e = this.tx,
      f = this.ty;

    var quot = 1 / (a * d - b * c);

    var aInv = d * quot;
    var bInv = -b * quot;
    var cInv = -c * quot;
    var dInv = a * quot;
    var eInv = -aInv * e - cInv * f;
    var fInv = -bInv * e - dInv * f;

    return new Matrix(aInv, bInv, cInv, dInv, eInv, fInv);
  };

  Matrix.prototype.applyToPoint = function(pt) {
    var x = pt.x * this.sx + pt.y * this.shx + this.tx;
    var y = pt.x * this.shy + pt.y * this.sy + this.ty;
    return new Point(x, y);
  };

  Matrix.prototype.applyToRectangle = function(rect) {
    var pt1 = this.applyToPoint(rect);
    var pt2 = this.applyToPoint(new Point(rect.x + rect.w, rect.y + rect.h));
    return new Rectangle(pt1.x, pt1.y, pt2.x - pt1.x, pt2.y - pt1.y);
  };

  Matrix.prototype.clone = function() {
    var sx = this.sx;
    var shy = this.shy;
    var shx = this.shx;
    var sy = this.sy;
    var tx = this.tx;
    var ty = this.ty;

    return new Matrix(sx, shy, shx, sy, tx, ty);
  };

  API.Matrix = Matrix;

  var matrixMult = (API.matrixMult = function(m1, m2) {
    return m2.multiply(m1);
  });

  var identityMatrix = new Matrix(1, 0, 0, 1, 0, 0);
  API.unitMatrix = API.identityMatrix = identityMatrix;

  var addPattern = function(key, pattern) {
    if (patternMap[key]) return;

    var prefix = pattern instanceof ShadingPattern ? "Sh" : "P";
    var patternKey = prefix + (Object.keys(patterns).length + 1).toString(10);
    pattern.id = patternKey;

    patternMap[key] = patternKey;
    patterns[patternKey] = pattern;

    events.publish("addPattern", pattern);
  };

  
  API.ShadingPattern = ShadingPattern;

  API.TilingPattern = TilingPattern;

  API.addShadingPattern = function(key, pattern) {
    advancedApiModeTrap("addShadingPattern()");

    addPattern(key, pattern);
    return this;
  };

  API.beginTilingPattern = function(pattern) {
    advancedApiModeTrap("beginTilingPattern()");

    beginNewRenderTarget(
      pattern.boundingBox[0],
      pattern.boundingBox[1],
      pattern.boundingBox[2] - pattern.boundingBox[0],
      pattern.boundingBox[3] - pattern.boundingBox[1],
      pattern.matrix
    );
  };

  API.endTilingPattern = function(key, pattern) {
    advancedApiModeTrap("endTilingPattern()");
    pattern.stream = pages[currentPage].join("\n");
    addPattern(key, pattern);
    events.publish("endTilingPattern", pattern);
    renderTargetStack.pop().restore();
  };
  var newObject = (API.__private__.newObject = function() {
    var oid = newObjectDeferred();
    newObjectDeferredBegin(oid, true);
    return oid;
  });
  var newObjectDeferred = (API.__private__.newObjectDeferred = function() {
    objectNumber++;
    offsets[objectNumber] = function() {
      return contentLength;
    };
    return objectNumber;
  });
  var newObjectDeferredBegin = function(oid, doOutput) {
    doOutput = typeof doOutput === "boolean" ? doOutput : false;
    offsets[oid] = contentLength;
    if (doOutput) {
      out(oid + " 0 obj");
    }
    return oid;
  };
  var newAdditionalObject = (API.__private__.newAdditionalObject = function() {
    var objId = newObjectDeferred();
    var obj = {
      objId: objId,
      content: ""
    };
    additionalObjects.push(obj);
    return obj;
  });
  var rootDictionaryObjId = newObjectDeferred();
  var resourceDictionaryObjId = newObjectDeferred();
  var decodeColorString = (API.__private__.decodeColorString = function(color) {
    var colorEncoded = color.split(" ");
    if (
      colorEncoded.length === 2 &&
      (colorEncoded[1] === "g" || colorEncoded[1] === "G")
    ) {
      var floatVal = parseFloat(colorEncoded[0]);
      colorEncoded = [floatVal, floatVal, floatVal, "r"];
    } else if (
      colorEncoded.length === 5 &&
      (colorEncoded[4] === "k" || colorEncoded[4] === "K")
    ) {
      var red = (1.0 - colorEncoded[0]) * (1.0 - colorEncoded[3]);
      var green = (1.0 - colorEncoded[1]) * (1.0 - colorEncoded[3]);
      var blue = (1.0 - colorEncoded[2]) * (1.0 - colorEncoded[3]);

      colorEncoded = [red, green, blue, "r"];
    }
    var colorAsRGB = "#";
    for (var i = 0; i < 3; i++) {
      colorAsRGB += (
        "0" + Math.floor(parseFloat(colorEncoded[i]) * 255).toString(16)
      ).slice(-2);
    }
    return colorAsRGB;
  });

  var encodeColorString = (API.__private__.encodeColorString = function(
    options
  ) {
    var color;

    if (typeof options === "string") {
      options = {
        ch1: options
      };
    }
    var ch1 = options.ch1;
    var ch2 = options.ch2;
    var ch3 = options.ch3;
    var ch4 = options.ch4;
    var letterArray =
      options.pdfColorType === "draw" ? ["G", "RG", "K"] : ["g", "rg", "k"];

    if (typeof ch1 === "string" && ch1.charAt(0) !== "#") {
      var rgbColor = new RGBColor(ch1);
      if (rgbColor.ok) {
        ch1 = rgbColor.toHex();
      } else if (!/^\d*\.?\d*$/.test(ch1)) {
        throw new Error(
          'Invalid color "' + ch1 + '" passed to jsPDF.encodeColorString.'
        );
      }
    }
    if (typeof ch1 === "string" && /^#[0-9A-Fa-f]{3}$/.test(ch1)) {
      ch1 = "#" + ch1[1] + ch1[1] + ch1[2] + ch1[2] + ch1[3] + ch1[3];
    }

    if (typeof ch1 === "string" && /^#[0-9A-Fa-f]{6}$/.test(ch1)) {
      var hex = parseInt(ch1.substr(1), 16);
      ch1 = (hex >> 16) & 255;
      ch2 = (hex >> 8) & 255;
      ch3 = hex & 255;
    }
    if (
      typeof ch2 === "undefined" ||
      (typeof ch4 === "undefined" && ch1 === ch2 && ch2 === ch3)
    ) {
      if (typeof ch1 === "string") {
        color = ch1 + " " + letterArray[0];
      } else {
        switch (options.precision) {
          case 2:
            color = f2(ch1 / 255) + " " + letterArray[0];
            break;
          case 3:
          default:
            color = f3(ch1 / 255) + " " + letterArray[0];
        }
      }
    } else if (typeof ch4 === "undefined" || typeof ch4 === "object") {
      if (ch4 && !isNaN(ch4.a)) {
        if (ch4.a === 0) {
          color = ["1.", "1.", "1.", letterArray[1]].join(" ");
          return color;
        }
      }
      if (typeof ch1 === "string") {
        color = [ch1, ch2, ch3, letterArray[1]].join(" ");
      } else {
        switch (options.precision) {
          case 2:
            color = [
              f2(ch1 / 255),
              f2(ch2 / 255),
              f2(ch3 / 255),
              letterArray[1]
            ].join(" ");
            break;
          default:
          case 3:
            color = [
              f3(ch1 / 255),
              f3(ch2 / 255),
              f3(ch3 / 255),
              letterArray[1]
            ].join(" ");
        }
      }
    } else {
      if (typeof ch1 === "string") {
        color = [ch1, ch2, ch3, ch4, letterArray[2]].join(" ");
      } else {
        switch (options.precision) {
          case 2:
            color = [f2(ch1), f2(ch2), f2(ch3), f2(ch4), letterArray[2]].join(
              " "
            );
            break;
          case 3:
          default:
            color = [f3(ch1), f3(ch2), f3(ch3), f3(ch4), letterArray[2]].join(
              " "
            );
        }
      }
    }
    return color;
  });

  var getFilters = (API.__private__.getFilters = function() {
    return filters;
  });

  var putStream = (API.__private__.putStream = function(options) {
    options = options || {};
    var data = options.data || "";
    var filters = options.filters || getFilters();
    var alreadyAppliedFilters = options.alreadyAppliedFilters || [];
    var addLength1 = options.addLength1 || false;
    var valueOfLength1 = data.length;
    var objectId = options.objectId;
    var encryptor = function(data) {
      return data;
    };
    if (encryptionOptions !== null && typeof objectId == "undefined") {
      throw new Error(
        "ObjectId must be passed to putStream for file encryption"
      );
    }
    if (encryptionOptions !== null) {
      encryptor = encryption.encryptor(objectId, 0);
    }

    var processedData = {};
    if (filters === true) {
      filters = ["FlateEncode"];
    }
    var keyValues = options.additionalKeyValues || [];
    if (typeof jsPDF.API.processDataByFilters !== "undefined") {
      processedData = jsPDF.API.processDataByFilters(data, filters);
    } else {
      processedData = { data: data, reverseChain: [] };
    }
    var filterAsString =
      processedData.reverseChain +
      (Array.isArray(alreadyAppliedFilters)
        ? alreadyAppliedFilters.join(" ")
        : alreadyAppliedFilters.toString());

    if (processedData.data.length !== 0) {
      keyValues.push({
        key: "Length",
        value: processedData.data.length
      });
      if (addLength1 === true) {
        keyValues.push({
          key: "Length1",
          value: valueOfLength1
        });
      }
    }

    if (filterAsString.length != 0) {
      if (filterAsString.split("/").length - 1 === 1) {
        keyValues.push({
          key: "Filter",
          value: filterAsString
        });
      } else {
        keyValues.push({
          key: "Filter",
          value: "[" + filterAsString + "]"
        });

        for (var j = 0; j < keyValues.length; j += 1) {
          if (keyValues[j].key === "DecodeParms") {
            var decodeParmsArray = [];

            for (
              var i = 0;
              i < processedData.reverseChain.split("/").length - 1;
              i += 1
            ) {
              decodeParmsArray.push("null");
            }

            decodeParmsArray.push(keyValues[j].value);
            keyValues[j].value = "[" + decodeParmsArray.join(" ") + "]";
          }
        }
      }
    }

    out("<<");
    for (var k = 0; k < keyValues.length; k++) {
      out("/" + keyValues[k].key + " " + keyValues[k].value);
    }
    out(">>");
    if (processedData.data.length !== 0) {
      out("stream");
      out(encryptor(processedData.data));
      out("endstream");
    }
  });

  var putPage = (API.__private__.putPage = function(page) {
    var pageNumber = page.number;
    var data = page.data;
    var pageObjectNumber = page.objId;
    var pageContentsObjId = page.contentsObjId;

    newObjectDeferredBegin(pageObjectNumber, true);
    out("<</Type /Page");
    out("/Parent " + page.rootDictionaryObjId + " 0 R");
    out("/Resources " + page.resourceDictionaryObjId + " 0 R");
    out(
      "/MediaBox [" +
        parseFloat(hpf(page.mediaBox.bottomLeftX)) +
        " " +
        parseFloat(hpf(page.mediaBox.bottomLeftY)) +
        " " +
        hpf(page.mediaBox.topRightX) +
        " " +
        hpf(page.mediaBox.topRightY) +
        "]"
    );
    if (page.cropBox !== null) {
      out(
        "/CropBox [" +
          hpf(page.cropBox.bottomLeftX) +
          " " +
          hpf(page.cropBox.bottomLeftY) +
          " " +
          hpf(page.cropBox.topRightX) +
          " " +
          hpf(page.cropBox.topRightY) +
          "]"
      );
    }
    if (page.bleedBox !== null) {
      out(
        "/BleedBox [" +
          hpf(page.bleedBox.bottomLeftX) +
          " " +
          hpf(page.bleedBox.bottomLeftY) +
          " " +
          hpf(page.bleedBox.topRightX) +
          " " +
          hpf(page.bleedBox.topRightY) +
          "]"
      );
    }

    if (page.trimBox !== null) {
      out(
        "/TrimBox [" +
          hpf(page.trimBox.bottomLeftX) +
          " " +
          hpf(page.trimBox.bottomLeftY) +
          " " +
          hpf(page.trimBox.topRightX) +
          " " +
          hpf(page.trimBox.topRightY) +
          "]"
      );
    }

    if (page.artBox !== null) {
      out(
        "/ArtBox [" +
          hpf(page.artBox.bottomLeftX) +
          " " +
          hpf(page.artBox.bottomLeftY) +
          " " +
          hpf(page.artBox.topRightX) +
          " " +
          hpf(page.artBox.topRightY) +
          "]"
      );
    }
    if (typeof page.userUnit === "number" && page.userUnit !== 1.0) {
      out("/UserUnit " + page.userUnit);
    }

    events.publish("putPage", {
      objId: pageObjectNumber,
      pageContext: pagesContext[pageNumber],
      pageNumber: pageNumber,
      page: data
    });
    out("/Contents " + pageContentsObjId + " 0 R");
    out(">>");
    out("endobj");
    var pageContent = data.join("\n");

    if (apiMode === ApiMode.ADVANCED) {
      pageContent += "\nQ";
    }

    newObjectDeferredBegin(pageContentsObjId, true);
    putStream({
      data: pageContent,
      filters: getFilters(),
      objectId: pageContentsObjId
    });
    out("endobj");
    return pageObjectNumber;
  });

  var putPages = (API.__private__.putPages = function() {
    var n,
      i,
      pageObjectNumbers = [];

    for (n = 1; n <= page; n++) {
      pagesContext[n].objId = newObjectDeferred();
      pagesContext[n].contentsObjId = newObjectDeferred();
    }

    for (n = 1; n <= page; n++) {
      pageObjectNumbers.push(
        putPage({
          number: n,
          data: pages[n],
          objId: pagesContext[n].objId,
          contentsObjId: pagesContext[n].contentsObjId,
          mediaBox: pagesContext[n].mediaBox,
          cropBox: pagesContext[n].cropBox,
          bleedBox: pagesContext[n].bleedBox,
          trimBox: pagesContext[n].trimBox,
          artBox: pagesContext[n].artBox,
          userUnit: pagesContext[n].userUnit,
          rootDictionaryObjId: rootDictionaryObjId,
          resourceDictionaryObjId: resourceDictionaryObjId
        })
      );
    }
    newObjectDeferredBegin(rootDictionaryObjId, true);
    out("<</Type /Pages");
    var kids = "/Kids [";
    for (i = 0; i < page; i++) {
      kids += pageObjectNumbers[i] + " 0 R ";
    }
    out(kids + "]");
    out("/Count " + page);
    out(">>");
    out("endobj");
    events.publish("postPutPages");
  });

  var putFont = function(font) {
    events.publish("putFont", {
      font: font,
      out: out,
      newObject: newObject,
      putStream: putStream
    });

    if (font.isAlreadyPutted !== true) {
      font.objectNumber = newObject();
      out("<<");
      out("/Type /Font");
      out("/BaseFont /" + toPDFName(font.postScriptName));
      out("/Subtype /Type1");
      if (typeof font.encoding === "string") {
        out("/Encoding /" + font.encoding);
      }
      out("/FirstChar 32");
      out("/LastChar 255");
      out(">>");
      out("endobj");
    }
  };

  var putFonts = function() {
    for (var fontKey in fonts) {
      if (fonts.hasOwnProperty(fontKey)) {
        if (
          putOnlyUsedFonts === false ||
          (putOnlyUsedFonts === true && usedFonts.hasOwnProperty(fontKey))
        ) {
          putFont(fonts[fontKey]);
        }
      }
    }
  };

  var putXObject = function(xObject) {
    xObject.objectNumber = newObject();

    var options = [];
    options.push({ key: "Type", value: "/XObject" });
    options.push({ key: "Subtype", value: "/Form" });
    options.push({
      key: "BBox",
      value:
        "[" +
        [
          hpf(xObject.x),
          hpf(xObject.y),
          hpf(xObject.x + xObject.width),
          hpf(xObject.y + xObject.height)
        ].join(" ") +
        "]"
    });
    options.push({
      key: "Matrix",
      value: "[" + xObject.matrix.toString() + "]"
    });
    var stream = xObject.pages[1].join("\n");
    putStream({
      data: stream,
      additionalKeyValues: options,
      objectId: xObject.objectNumber
    });
    out("endobj");
  };

  var putXObjects = function() {
    for (var xObjectKey in renderTargets) {
      if (renderTargets.hasOwnProperty(xObjectKey)) {
        putXObject(renderTargets[xObjectKey]);
      }
    }
  };

  var interpolateAndEncodeRGBStream = function(colors, numberSamples) {
    var tValues = [];
    var t;
    var dT = 1.0 / (numberSamples - 1);
    for (t = 0.0; t < 1.0; t += dT) {
      tValues.push(t);
    }
    tValues.push(1.0);
    if (colors[0].offset != 0.0) {
      var c0 = {
        offset: 0.0,
        color: colors[0].color
      };
      colors.unshift(c0);
    }
    if (colors[colors.length - 1].offset != 1.0) {
      var c1 = {
        offset: 1.0,
        color: colors[colors.length - 1].color
      };
      colors.push(c1);
    }
    var out = "";
    var index = 0;

    for (var i = 0; i < tValues.length; i++) {
      t = tValues[i];
      while (t > colors[index + 1].offset) index++;
      var a = colors[index].offset;
      var b = colors[index + 1].offset;
      var d = (t - a) / (b - a);

      var aColor = colors[index].color;
      var bColor = colors[index + 1].color;

      out +=
        padd2Hex(Math.round((1 - d) * aColor[0] + d * bColor[0]).toString(16)) +
        padd2Hex(Math.round((1 - d) * aColor[1] + d * bColor[1]).toString(16)) +
        padd2Hex(Math.round((1 - d) * aColor[2] + d * bColor[2]).toString(16));
    }
    return out.trim();
  };
  var putShadingPattern = function(pattern, numberSamples) {
    numberSamples || (numberSamples = 21);
    var funcObjectNumber = newObject();
    var stream = interpolateAndEncodeRGBStream(pattern.colors, numberSamples);

    var options = [];
    options.push({ key: "FunctionType", value: "0" });
    options.push({ key: "Domain", value: "[0.0 1.0]" });
    options.push({ key: "Size", value: "[" + numberSamples + "]" });
    options.push({ key: "BitsPerSample", value: "8" });
    options.push({ key: "Range", value: "[0.0 1.0 0.0 1.0 0.0 1.0]" });
    options.push({ key: "Decode", value: "[0.0 1.0 0.0 1.0 0.0 1.0]" });
    putStream({
      data: stream,
      additionalKeyValues: options,
      alreadyAppliedFilters: ["/ASCIIHexDecode"],
      objectId: funcObjectNumber
    });
    out("endobj");
    pattern.objectNumber = newObject();
    out("<< /ShadingType " + pattern.type);
    out("/ColorSpace /DeviceRGB");
    var coords =
      "/Coords [" +
      hpf(parseFloat(pattern.coords[0])) +
      " " +
      hpf(parseFloat(pattern.coords[1])) +
      " ";
    if (pattern.type === 2) {
      coords +=
        hpf(parseFloat(pattern.coords[2])) +
        " " + 
        hpf(parseFloat(pattern.coords[3]));
    } else {
      coords +=
        hpf(parseFloat(pattern.coords[2])) +
        " " +
        hpf(parseFloat(pattern.coords[3])) +
        " " +
        hpf(parseFloat(pattern.coords[4])) +
        " " +
        hpf(parseFloat(pattern.coords[5]));
    }
    coords += "]";
    out(coords);

    if (pattern.matrix) {
      out("/Matrix [" + pattern.matrix.toString() + "]");
    }
    out("/Function " + funcObjectNumber + " 0 R");
    out("/Extend [true true]");
    out(">>");
    out("endobj");
  };

  var putTilingPattern = function(pattern, deferredResourceDictionaryIds) {
    var resourcesObjectId = newObjectDeferred();
    var patternObjectId = newObject();

    deferredResourceDictionaryIds.push({
      resourcesOid: resourcesObjectId,
      objectOid: patternObjectId
    });

    pattern.objectNumber = patternObjectId;
    var options = [];
    options.push({ key: "Type", value: "/Pattern" });
    options.push({ key: "PatternType", value: "1" });
    options.push({ key: "PaintType", value: "1" });
    options.push({ key: "TilingType", value: "1" });
    options.push({
      key: "BBox",
      value: "[" + pattern.boundingBox.map(hpf).join(" ") + "]"
    });
    options.push({ key: "XStep", value: hpf(pattern.xStep) });
    options.push({ key: "YStep", value: hpf(pattern.yStep) });
    options.push({ key: "Resources", value: resourcesObjectId + " 0 R" });
    if (pattern.matrix) {
      options.push({
        key: "Matrix",
        value: "[" + pattern.matrix.toString() + "]"
      });
    }
    putStream({
      data: pattern.stream,
      additionalKeyValues: options,
      objectId: pattern.objectNumber
    });
    out("endobj");
  };
  var putPatterns = function(deferredResourceDictionaryIds) {
    var patternKey;
    for (patternKey in patterns) {
      if (patterns.hasOwnProperty(patternKey)) {
        if (patterns[patternKey] instanceof ShadingPattern) {
          putShadingPattern(patterns[patternKey]);
        } else if (patterns[patternKey] instanceof TilingPattern) {
          putTilingPattern(patterns[patternKey], deferredResourceDictionaryIds);
        }
      }
    }
  };
  var putGState = function(gState) {
    gState.objectNumber = newObject();
    out("<<");
    for (var p in gState) {
      switch (p) {
        case "opacity":
          out("/ca " + f2(gState[p]));
          break;
        case "stroke-opacity":
          out("/CA " + f2(gState[p]));
          break;
      }
    }
    out(">>");
    out("endobj");
  };
  var putGStates = function() {
    var gStateKey;
    for (gStateKey in gStates) {
      if (gStates.hasOwnProperty(gStateKey)) {
        putGState(gStates[gStateKey]);
      }
    }
  };
  var putXobjectDict = function() {
    out("/XObject <<");
    for (var xObjectKey in renderTargets) {
      if (
        renderTargets.hasOwnProperty(xObjectKey) &&
        renderTargets[xObjectKey].objectNumber >= 0
      ) {
        out(
          "/" +
            xObjectKey +
            " " +
            renderTargets[xObjectKey].objectNumber +
            " 0 R"
        );
      }
    }
    events.publish("putXobjectDict");
    out(">>");
  };

  var putEncryptionDict = function() {
    encryption.oid = newObject();
    out("<<");
    out("/Filter /Standard");
    out("/V " + encryption.v);
    out("/R " + encryption.r);
    out("/U <" + encryption.toHexString(encryption.U) + ">");
    out("/O <" + encryption.toHexString(encryption.O) + ">");
    out("/P " + encryption.P);
    out(">>");
    out("endobj");
  };

  var putFontDict = function() {
    out("/Font <<");

    for (var fontKey in fonts) {
      if (fonts.hasOwnProperty(fontKey)) {
        if (
          putOnlyUsedFonts === false ||
          (putOnlyUsedFonts === true && usedFonts.hasOwnProperty(fontKey))
        ) {
          out("/" + fontKey + " " + fonts[fontKey].objectNumber + " 0 R");
        }
      }
    }
    out(">>");
  };
  var putShadingPatternDict = function() {
    if (Object.keys(patterns).length > 0) {
      out("/Shading <<");
      for (var patternKey in patterns) {
        if (
          patterns.hasOwnProperty(patternKey) &&
          patterns[patternKey] instanceof ShadingPattern &&
          patterns[patternKey].objectNumber >= 0
        ) {
          out(
            "/" + patternKey + " " + patterns[patternKey].objectNumber + " 0 R"
          );
        }
      }
      events.publish("putShadingPatternDict");
      out(">>");
    }
  };
  var putTilingPatternDict = function(objectOid) {
    if (Object.keys(patterns).length > 0) {
      out("/Pattern <<");
      for (var patternKey in patterns) {
        if (
          patterns.hasOwnProperty(patternKey) &&
          patterns[patternKey] instanceof API.TilingPattern &&
          patterns[patternKey].objectNumber >= 0 &&
          patterns[patternKey].objectNumber < objectOid
        ) {
          out(
            "/" + patternKey + " " + patterns[patternKey].objectNumber + " 0 R"
          );
        }
      }
      events.publish("putTilingPatternDict");
      out(">>");
    }
  };
  var putGStatesDict = function() {
    if (Object.keys(gStates).length > 0) {
      var gStateKey;
      out("/ExtGState <<");
      for (gStateKey in gStates) {
        if (
          gStates.hasOwnProperty(gStateKey) &&
          gStates[gStateKey].objectNumber >= 0
        ) {
          out("/" + gStateKey + " " + gStates[gStateKey].objectNumber + " 0 R");
        }
      }
      events.publish("putGStateDict");
      out(">>");
    }
  };
  var putResourceDictionary = function(objectIds) {
    newObjectDeferredBegin(objectIds.resourcesOid, true);
    out("<<");
    out("/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]");
    putFontDict();
    putShadingPatternDict();
    putTilingPatternDict(objectIds.objectOid);
    putGStatesDict();
    putXobjectDict();
    out(">>");
    out("endobj");
  };
  var putResources = function() {
    var deferredResourceDictionaryIds = [];
    putFonts();
    putGStates();
    putXObjects();
    putPatterns(deferredResourceDictionaryIds);
    events.publish("putResources");
    deferredResourceDictionaryIds.forEach(putResourceDictionary);
    putResourceDictionary({
      resourcesOid: resourceDictionaryObjId,
      objectOid: Number.MAX_SAFE_INTEGER
    });
    events.publish("postPutResources");
  };

  var putAdditionalObjects = function() {
    events.publish("putAdditionalObjects");
    for (var i = 0; i < additionalObjects.length; i++) {
      var obj = additionalObjects[i];
      newObjectDeferredBegin(obj.objId, true);
      out(obj.content);
      out("endobj");
    }
    events.publish("postPutAdditionalObjects");
  };

  var addFontToFontDictionary = function(font) {
    fontmap[font.fontName] = fontmap[font.fontName] || {};
    fontmap[font.fontName][font.fontStyle] = font.id;
  };

  var addFont = function(
    postScriptName,
    fontName,
    fontStyle,
    encoding,
    isStandardFont
  ) {
    var font = {
      id: "F" + (Object.keys(fonts).length + 1).toString(10),
      postScriptName: postScriptName,
      fontName: fontName,
      fontStyle: fontStyle,
      encoding: encoding,
      isStandardFont: isStandardFont || false,
      metadata: {}
    };

    events.publish("addFont", {
      font: font,
      instance: this
    });

    fonts[font.id] = font;
    addFontToFontDictionary(font);
    return font.id;
  };

  var addFonts = function(arrayOfFonts) {
    for (var i = 0, l = standardFonts.length; i < l; i++) {
      var fontKey = addFont.call(
        this,
        arrayOfFonts[i][0],
        arrayOfFonts[i][1],
        arrayOfFonts[i][2],
        standardFonts[i][3],
        true
      );

      if (putOnlyUsedFonts === false) {
        usedFonts[fontKey] = true;
      }
      var parts = arrayOfFonts[i][0].split("-");
      addFontToFontDictionary({
        id: fontKey,
        fontName: parts[0],
        fontStyle: parts[1] || ""
      });
    }
    events.publish("addFonts", {
      fonts: fonts,
      dictionary: fontmap
    });
  };

  var SAFE = function __safeCall(fn) {
    fn.foo = function __safeCallWrapper() {
      try {
        return fn.apply(this, arguments);
      } catch (e) {
        var stack = e.stack || "";
        if (~stack.indexOf(" at ")) stack = stack.split(" at ")[1];
        var m =
          "Error in function " +
          stack.split("\n")[0].split("<")[0] +
          ": " +
          e.message;
        if (globalObject.console) {
          globalObject.console.error(m, e);
          if (globalObject.alert) alert(m);
        } else {
          throw new Error(m);
        }
      }
    };
    fn.foo.bar = fn;
    return fn.foo;
  };
  var to8bitStream = function(text, flags) {
    var i,
      l,
      sourceEncoding,
      encodingBlock,
      outputEncoding,
      newtext,
      isUnicode,
      ch,
      bch;

    flags = flags || {};
    sourceEncoding = flags.sourceEncoding || "Unicode";
    outputEncoding = flags.outputEncoding;

    if (
      (flags.autoencode || outputEncoding) &&
      fonts[activeFontKey].metadata &&
      fonts[activeFontKey].metadata[sourceEncoding] &&
      fonts[activeFontKey].metadata[sourceEncoding].encoding
    ) {
      encodingBlock = fonts[activeFontKey].metadata[sourceEncoding].encoding;
      if (!outputEncoding && fonts[activeFontKey].encoding) {
        outputEncoding = fonts[activeFontKey].encoding;
      }

      if (!outputEncoding && encodingBlock.codePages) {
        outputEncoding = encodingBlock.codePages[0];
      }

      if (typeof outputEncoding === "string") {
        outputEncoding = encodingBlock[outputEncoding];
      }
      if (outputEncoding) {
        isUnicode = false;
        newtext = [];
        for (i = 0, l = text.length; i < l; i++) {
          ch = outputEncoding[text.charCodeAt(i)];
          if (ch) {
            newtext.push(String.fromCharCode(ch));
          } else {
            newtext.push(text[i]);
          }
          if (newtext[i].charCodeAt(0) >> 8) {
            isUnicode = true;
          }
        }
        text = newtext.join("");
      }
    }

    i = text.length;
    while (isUnicode === undefined && i !== 0) {
      if (text.charCodeAt(i - 1) >> 8) {
        isUnicode = true;
      }
      i--;
    }
    if (!isUnicode) {
      return text;
    }

    newtext = flags.noBOM ? [] : [254, 255];
    for (i = 0, l = text.length; i < l; i++) {
      ch = text.charCodeAt(i);
      bch = ch >> 8;
      if (bch >> 8) {
        throw new Error(
          "Character at position " +
            i +
            " of string '" +
            text +
            "' exceeds 16bits. Cannot be encoded into UCS-2 BE"
        );
      }
      newtext.push(bch);
      newtext.push(ch - (bch << 8));
    }
    return String.fromCharCode.apply(undefined, newtext);
  };

  var pdfEscape = (API.__private__.pdfEscape = API.pdfEscape = function(
    text,
    flags
  ) {
    
    return to8bitStream(text, flags)
      .replace(/\\/g, "\\\\")
      .replace(/\(/g, "\\(")
      .replace(/\)/g, "\\)");
  });

  var beginPage = (API.__private__.beginPage = function(format) {
    pages[++page] = [];
    pagesContext[page] = {
      objId: 0,
      contentsObjId: 0,
      userUnit: Number(userUnit),
      artBox: null,
      bleedBox: null,
      cropBox: null,
      trimBox: null,
      mediaBox: {
        bottomLeftX: 0,
        bottomLeftY: 0,
        topRightX: Number(format[0]),
        topRightY: Number(format[1])
      }
    };
    _setPage(page);
    setOutputDestination(pages[currentPage]);
  });

  var _addPage = function(parmFormat, parmOrientation) {
    var dimensions, width, height;

    orientation = parmOrientation || orientation;

    if (typeof parmFormat === "string") {
      dimensions = getPageFormat(parmFormat.toLowerCase());
      if (Array.isArray(dimensions)) {
        width = dimensions[0];
        height = dimensions[1];
      }
    }

    if (Array.isArray(parmFormat)) {
      width = parmFormat[0] * scaleFactor;
      height = parmFormat[1] * scaleFactor;
    }

    if (isNaN(width)) {
      width = format[0];
      height = format[1];
    }

    if (width > 14400 || height > 14400) {
      console.warn(
        "A page in a PDF can not be wider or taller than 14400 userUnit. jsPDF limits the width/height to 14400"
      );
      width = Math.min(14400, width);
      height = Math.min(14400, height);
    }

    format = [width, height];

    switch (orientation.substr(0, 1)) {
      case "l":
        if (height > width) {
          format = [height, width];
        }
        break;
      case "p":
        if (width > height) {
          format = [height, width];
        }
        break;
    }

    beginPage(format);
    setLineWidth(lineWidth);
    out(strokeColor);
    if (lineCapID !== 0) {
      out(lineCapID + " J");
    }
    if (lineJoinID !== 0) {
      out(lineJoinID + " j");
    }
    events.publish("addPage", {
      pageNumber: page
    });
  };

  var _deletePage = function(n) {
    if (n > 0 && n <= page) {
      pages.splice(n, 1);
      pagesContext.splice(n, 1);
      page--;
      if (currentPage > page) {
        currentPage = page;
      }
      this.setPage(currentPage);
    }
  };

  var _setPage = function(n) {
    if (n > 0 && n <= page) {
      currentPage = n;
    }
  };

  var getNumberOfPages = (API.__private__.getNumberOfPages = API.getNumberOfPages = function() {
    return pages.length - 1;
  });

  
  var getFont = function(fontName, fontStyle, options) {
    var key = undefined,
      fontNameLowerCase;
    options = options || {};

    fontName =
      fontName !== undefined ? fontName : fonts[activeFontKey].fontName;
    fontStyle =
      fontStyle !== undefined ? fontStyle : fonts[activeFontKey].fontStyle;
    fontNameLowerCase = fontName.toLowerCase();

    if (
      fontmap[fontNameLowerCase] !== undefined &&
      fontmap[fontNameLowerCase][fontStyle] !== undefined
    ) {
      key = fontmap[fontNameLowerCase][fontStyle];
    } else if (
      fontmap[fontName] !== undefined &&
      fontmap[fontName][fontStyle] !== undefined
    ) {
      key = fontmap[fontName][fontStyle];
    } else {
      if (options.disableWarning === false) {
        console.warn(
          "Unable to look up font label for font '" +
            fontName +
            "', '" +
            fontStyle +
            "'. Refer to getFontList() for available fonts."
        );
      }
    }

    if (!key && !options.noFallback) {
      key = fontmap["times"][fontStyle];
      if (key == null) {
        key = fontmap["times"]["normal"];
      }
    }
    return key;
  };

  var putInfo = (API.__private__.putInfo = function() {
    var objectId = newObject();
    var encryptor = function(data) {
      return data;
    };
    if (encryptionOptions !== null) {
      encryptor = encryption.encryptor(objectId, 0);
    }
    out("<<");
    out("/Producer (" + pdfEscape(encryptor("jsPDF " + jsPDF.version)) + ")");
    for (var key in documentProperties) {
      if (documentProperties.hasOwnProperty(key) && documentProperties[key]) {
        out(
          "/" +
            key.substr(0, 1).toUpperCase() +
            key.substr(1) +
            " (" +
            pdfEscape(encryptor(documentProperties[key])) +
            ")"
        );
      }
    }
    out("/CreationDate (" + pdfEscape(encryptor(creationDate)) + ")");
    out(">>");
    out("endobj");
  });

  var putCatalog = (API.__private__.putCatalog = function(options) {
    options = options || {};
    var tmpRootDictionaryObjId =
      options.rootDictionaryObjId || rootDictionaryObjId;
    newObject();
    out("<<");
    out("/Type /Catalog");
    out("/Pages " + tmpRootDictionaryObjId + " 0 R");
    if (!zoomMode) zoomMode = "fullwidth";
    switch (zoomMode) {
      case "fullwidth":
        out("/OpenAction [3 0 R /FitH null]");
        break;
      case "fullheight":
        out("/OpenAction [3 0 R /FitV null]");
        break;
      case "fullpage":
        out("/OpenAction [3 0 R /Fit]");
        break;
      case "original":
        out("/OpenAction [3 0 R /XYZ null null 1]");
        break;
      default:
        var pcn = "" + zoomMode;
        if (pcn.substr(pcn.length - 1) === "%")
          zoomMode = parseInt(zoomMode) / 100;
        if (typeof zoomMode === "number") {
          out("/OpenAction [3 0 R /XYZ null null " + f2(zoomMode) + "]");
        }
    }
    if (!layoutMode) layoutMode = "continuous";
    switch (layoutMode) {
      case "continuous":
        out("/PageLayout /OneColumn");
        break;
      case "single":
        out("/PageLayout /SinglePage");
        break;
      case "two":
      case "twoleft":
        out("/PageLayout /TwoColumnLeft");
        break;
      case "tworight":
        out("/PageLayout /TwoColumnRight");
        break;
    }
    if (pageMode) {
      out("/PageMode /" + pageMode);
    }
    events.publish("putCatalog");
    out(">>");
    out("endobj");
  });

  var putTrailer = (API.__private__.putTrailer = function() {
    out("trailer");
    out("<<");
    out("/Size " + (objectNumber + 1));
    out("/Root " + objectNumber + " 0 R");
    out("/Info " + (objectNumber - 1) + " 0 R");
    if (encryptionOptions !== null) {
      out("/Encrypt " + encryption.oid + " 0 R");
    }
    out("/ID [ <" + fileId + "> <" + fileId + "> ]");
    out(">>");
  });
  var putHeader = (API.__private__.putHeader = function() {
    out("%PDF-" + pdfVersion);
    out("%\xBA\xDF\xAC\xE0");
  });
  var putXRef = (API.__private__.putXRef = function() {
    var p = "0000000000";
    out("xref");
    out("0 " + (objectNumber + 1));
    out("0000000000 65535 f ");
    for (var i = 1; i <= objectNumber; i++) {
      var offset = offsets[i];
      if (typeof offset === "function") {
        out((p + offsets[i]()).slice(-10) + " 00000 n ");
      } else {
        if (typeof offsets[i] !== "undefined") {
          out((p + offsets[i]).slice(-10) + " 00000 n ");
        } else {
          out("0000000000 00000 n ");
        }
      }
    }
  });
  var buildDocument = (API.__private__.buildDocument = function() {
    resetDocument();
    setOutputDestination(content);
    events.publish("buildDocument");
    putHeader();
    putPages();
    putAdditionalObjects();
    putResources();
    if (encryptionOptions !== null) putEncryptionDict();
    putInfo();
    putCatalog();
    var offsetOfXRef = contentLength;
    putXRef();
    putTrailer();
    out("startxref");
    out("" + offsetOfXRef);
    out("%%EOF");
    setOutputDestination(pages[currentPage]);
    return content.join("\n");
  })
  var getBlob = (API.__private__.getBlob = function(data) {
    return new Blob([getArrayBuffer(data)], {
      type: "application/pdf"
    });
  });
  var output = (API.output = API.__private__.output = SAFE(function output(
    type,
    options
  ) {
    options = options || {};

    if (typeof options === "string") {
      options = {
        filename: options
      };
    } else {
      options.filename = options.filename || "generated.pdf";
    }

    switch (type) {
      case undefined:
        return buildDocument();
      case "save":
        API.save(options.filename);
        break;
      case "arraybuffer":
        return getArrayBuffer(buildDocument());
      case "blob":
        return getBlob(buildDocument());
      case "bloburi":
      case "bloburl":
        if (
          typeof globalObject.URL !== "undefined" &&
          typeof globalObject.URL.createObjectURL === "function"
        ) {
          return (
            (globalObject.URL &&
              globalObject.URL.createObjectURL(getBlob(buildDocument()))) ||
            void 0
          );
        } else {
          console.warn(
            "bloburl is not supported by your system, because URL.createObjectURL is not supported by your browser."
          );
        }
        break;
      case "datauristring":
      case "dataurlstring":
        var dataURI = "";
        var pdfDocument = buildDocument();
        try {
          dataURI = btoa(pdfDocument);
        } catch (e) {
          dataURI = btoa(unescape(encodeURIComponent(pdfDocument)));
        }
        return (
          "data:application/pdf;filename=" +
          options.filename +
          ";base64," +
          dataURI
        );
      case "pdfobjectnewwindow":
        if (
          Object.prototype.toString.call(globalObject) === "[object Window]"
        ) {
          var pdfObjectUrl =
            "https://cdnjs.cloudflare.com/ajax/libs/pdfobject/2.1.1/pdfobject.min.js";
          var integrity =
            ' integrity="sha512-4ze/a9/4jqu+tX9dfOqJYSvyYd5M6qum/3HpCLr+/Jqf0whc37VUbkpNGHR7/8pSnCFw47T1fmIpwBV7UySh3g==" crossorigin="anonymous"';

          if (options.pdfObjectUrl) {
            pdfObjectUrl = options.pdfObjectUrl;
            integrity = "";
          }

          var htmlForNewWindow =
            "<html>" +
            '<style>html, body { padding: 0; margin: 0; } iframe { width: 100%; height: 100%; border: 0;}  </style><body><script src="' +
            pdfObjectUrl +
            '"' +
            integrity +
            '></script><script >PDFObject.embed("' +
            this.output("dataurlstring") +
            '", ' +
            JSON.stringify(options) +
            ");</script></body></html>";
          var nW = globalObject.open();

          if (nW !== null) {
            nW.document.write(htmlForNewWindow);
          }
          return nW;
        } else {
          throw new Error(
            "The option pdfobjectnewwindow just works in a browser-environment."
          );
        }
      case "pdfjsnewwindow":
        if (
          Object.prototype.toString.call(globalObject) === "[object Window]"
        ) {
          var pdfJsUrl = options.pdfJsUrl || "examples/PDF.js/web/viewer.html";
          var htmlForPDFjsNewWindow =
            "<html>" +
            "<style>html, body { padding: 0; margin: 0; } iframe { width: 100%; height: 100%; border: 0;}  </style>" +
            '<body><iframe id="pdfViewer" src="' +
            pdfJsUrl +
            "?file=&downloadName=" +
            options.filename +
            '" width="500px" height="400px" />' +
            "</body></html>";
          var PDFjsNewWindow = globalObject.open();

          if (PDFjsNewWindow !== null) {
            PDFjsNewWindow.document.write(htmlForPDFjsNewWindow);
            var scope = this;
            PDFjsNewWindow.document.documentElement.querySelector(
              "#pdfViewer"
            ).onload = function() {
              PDFjsNewWindow.document.title = options.filename;
              PDFjsNewWindow.document.documentElement
                .querySelector("#pdfViewer")
                .contentWindow.PDFViewerApplication.open(
                  scope.output("bloburl")
                );
            };
          }
          return PDFjsNewWindow;
        } else {
          throw new Error(
            "The option pdfjsnewwindow just works in a browser-environment."
          );
        }
      case "dataurlnewwindow":
        if (
          Object.prototype.toString.call(globalObject) === "[object Window]"
        ) {
          var htmlForDataURLNewWindow =
            "<html>" +
            "<style>html, body { padding: 0; margin: 0; } iframe { width: 100%; height: 100%; border: 0;}  </style>" +
            "<body>" +
            '<iframe src="' +
            this.output("datauristring", options) +
            '"></iframe>' +
            "</body></html>";
          var dataURLNewWindow = globalObject.open();
          if (dataURLNewWindow !== null) {
            dataURLNewWindow.document.write(htmlForDataURLNewWindow);
            dataURLNewWindow.document.title = options.filename;
          }
          if (dataURLNewWindow || typeof safari === "undefined")
            return dataURLNewWindow;
        } else {
          throw new Error(
            "The option dataurlnewwindow just works in a browser-environment."
          );
        }
        break;
      case "datauri":
      case "dataurl":
        return (globalObject.document.location.href = this.output(
          "datauristring",
          options
        ));
      default:
        return null;
    }
  }));
  var hasHotfix = function(hotfixName) {
    return (
      Array.isArray(hotfixes) === true && hotfixes.indexOf(hotfixName) > -1
    );
  };
  switch (unit) {
    case "pt":
      scaleFactor = 1;
      break;
    case "mm":
      scaleFactor = 72 / 25.4;
      break;
    case "cm":
      scaleFactor = 72 / 2.54;
      break;
    case "in":
      scaleFactor = 72;
      break;
    case "px":
      if (hasHotfix("px_scaling") == true) {
        scaleFactor = 72 / 96;
      } else {
        scaleFactor = 96 / 72;
      }
      break;
    case "pc":
      scaleFactor = 12;
      break;
    case "em":
      scaleFactor = 12;
      break;
    case "ex":
      scaleFactor = 6;
      break;
    default:
      if (typeof unit === "number") {
        scaleFactor = unit;
      } else {
        throw new Error("Invalid unit: " + unit);
      }
  }
  var encryption = null;
  setCreationDate();
  setFileId();
  var getEncryptor = function(objectId) {
    if (encryptionOptions !== null) {
      return encryption.encryptor(objectId, 0);
    }
    return function(data) {
      return data;
    };
  };
  var getPageInfo = (API.__private__.getPageInfo = API.getPageInfo = function(
    pageNumberOneBased
  ) {
    if (isNaN(pageNumberOneBased) || pageNumberOneBased % 1 !== 0) {
      throw new Error("Invalid argument passed to jsPDF.getPageInfo");
    }
    var objId = pagesContext[pageNumberOneBased].objId;
    return {
      objId: objId,
      pageNumber: pageNumberOneBased,
      pageContext: pagesContext[pageNumberOneBased]
    };
  });

  var getPageInfoByObjId = (API.__private__.getPageInfoByObjId = function(
    objId
  ) {
    if (isNaN(objId) || objId % 1 !== 0) {
      throw new Error("Invalid argument passed to jsPDF.getPageInfoByObjId");
    }
    for (var pageNumber in pagesContext) {
      if (pagesContext[pageNumber].objId === objId) {
        break;
      }
    }
    return getPageInfo(pageNumber);
  });

  var getCurrentPageInfo = (API.__private__.getCurrentPageInfo = API.getCurrentPageInfo = function() {
    return {
      objId: pagesContext[currentPage].objId,
      pageNumber: currentPage,
      pageContext: pagesContext[currentPage]
    };
  });
  API.addPage = function() {
    _addPage.apply(this, arguments);
    return this;
  };
  API.setPage = function() {
    _setPage.apply(this, arguments);
    setOutputDestination.call(this, pages[currentPage]);
    return this;
  };
  API.insertPage = function(beforePage) {
    this.addPage();
    this.movePage(currentPage, beforePage);
    return this;
  };
  API.movePage = function(targetPage, beforePage) {
    var tmpPages, tmpPagesContext;
    if (targetPage > beforePage) {
      tmpPages = pages[targetPage];
      tmpPagesContext = pagesContext[targetPage];
      for (var i = targetPage; i > beforePage; i--) {
        pages[i] = pages[i - 1];
        pagesContext[i] = pagesContext[i - 1];
      }
      pages[beforePage] = tmpPages;
      pagesContext[beforePage] = tmpPagesContext;
      this.setPage(beforePage);
    } else if (targetPage < beforePage) {
      tmpPages = pages[targetPage];
      tmpPagesContext = pagesContext[targetPage];
      for (var j = targetPage; j < beforePage; j++) {
        pages[j] = pages[j + 1];
        pagesContext[j] = pagesContext[j + 1];
      }
      pages[beforePage] = tmpPages;
      pagesContext[beforePage] = tmpPagesContext;
      this.setPage(beforePage);
    }
    return this;
  };
  API.deletePage = function() {
    _deletePage.apply(this, arguments);
    return this;
  };
  API.__private__.text = API.text = function(text, x, y, options, transform) {
    options = options || {};
    var scope = options.scope || this;
    var payload, da, angle, align, charSpace, maxWidth, flags, horizontalScale;
    if (
      typeof text === "number" &&
      typeof x === "number" &&
      (typeof y === "string" || Array.isArray(y))
    ) {
      var tmp = y;
      y = x;
      x = text;
      text = tmp;
    }
    var transformationMatrix;
    if (arguments[3] instanceof Matrix === false) {
      flags = arguments[3];
      angle = arguments[4];
      align = arguments[5];
      if (typeof flags !== "object" || flags === null) {
        if (typeof angle === "string") {
          align = angle;
          angle = null;
        }
        if (typeof flags === "string") {
          align = flags;
          flags = null;
        }
        if (typeof flags === "number") {
          angle = flags;
          flags = null;
        }
        options = {
          flags: flags,
          angle: angle,
          align: align
        };
      }
    } else {
      advancedApiModeTrap(
        "The transform parameter of text() with a Matrix value"
      );
      transformationMatrix = transform;
    }
    if (isNaN(x) || isNaN(y) || typeof text === "undefined" || text === null) {
      throw new Error("Invalid arguments passed to jsPDF.text");
    }
    if (text.length === 0) {
      return scope;
    }
    var xtra = "";
    var isHex = false;
    var lineHeight =
      typeof options.lineHeightFactor === "number"
        ? options.lineHeightFactor
        : lineHeightFactor;
    var scaleFactor = scope.internal.scaleFactor;

    function ESC(s) {
      s = s.split("\t").join(Array(options.TabLen || 9).join(" "));
      return pdfEscape(s, flags);
    }
    function transformTextToSpecialArray(text) {
      var sa = text.concat();
      var da = [];
      var len = sa.length;
      var curDa;
      while (len--) {
        curDa = sa.shift();
        if (typeof curDa === "string") {
          da.push(curDa);
        } else {
          if (
            Array.isArray(text) &&
            (curDa.length === 1 ||
              (curDa[1] === undefined && curDa[2] === undefined))
          ) {
            da.push(curDa[0]);
          } else {
            da.push([curDa[0], curDa[1], curDa[2]]);
          }
        }
      }
      return da;
    }
    function processTextByFunction(text, processingFunction) {
      var result;
      if (typeof text === "string") {
        result = processingFunction(text)[0];
      } else if (Array.isArray(text)) {
        var sa = text.concat();
        var da = [];
        var len = sa.length;
        var curDa;
        var tmpResult;
        while (len--) {
          curDa = sa.shift();
          if (typeof curDa === "string") {
            da.push(processingFunction(curDa)[0]);
          } else if (Array.isArray(curDa) && typeof curDa[0] === "string") {
            tmpResult = processingFunction(curDa[0], curDa[1], curDa[2]);
            da.push([tmpResult[0], tmpResult[1], tmpResult[2]]);
          }
        }
        result = da;
      }
      return result;
    }
    var textIsOfTypeString = false;
    var tmpTextIsOfTypeString = true;
    if (typeof text === "string") {
      textIsOfTypeString = true;
    } else if (Array.isArray(text)) {
      var sa = text.concat();
      da = [];
      var len = sa.length;
      var curDa;
      while (len--) {
        curDa = sa.shift();
        if (
          typeof curDa !== "string" ||
          (Array.isArray(curDa) && typeof curDa[0] !== "string")
        ) {
          tmpTextIsOfTypeString = false;
        }
      }
      textIsOfTypeString = tmpTextIsOfTypeString;
    }
    if (textIsOfTypeString === false) {
      throw new Error(
        'Type of text must be string or Array. "' +
          text +
          '" is not recognized.'
      );
    }
    if (typeof text === "string") {
      if (text.match(/[\r?\n]/)) {
        text = text.split(/\r\n|\r|\n/g);
      } else {
        text = [text];
      }
    }
    var height = activeFontSize / scope.internal.scaleFactor;
    var descent = height * (lineHeight - 1);
    switch (options.baseline) {
      case "bottom":
        y -= descent;
        break;
      case "top":
        y += height - descent;
        break;
      case "hanging":
        y += height - 2 * descent;
        break;
      case "middle":
        y += height / 2 - descent;
        break;
      case "ideographic":
      case "alphabetic":
      default:
        break;
    }
    maxWidth = options.maxWidth || 0;
    if (maxWidth > 0) {
      if (typeof text === "string") {
        text = scope.splitTextToSize(text, maxWidth);
      } else if (Object.prototype.toString.call(text) === "[object Array]") {
        text = text.reduce(function(acc, textLine) {
          return acc.concat(scope.splitTextToSize(textLine, maxWidth));
        }, []);
      }
    }
    payload = {
      text: text,
      x: x,
      y: y,
      options: options,
      mutex: {
        pdfEscape: pdfEscape,
        activeFontKey: activeFontKey,
        fonts: fonts,
        activeFontSize: activeFontSize
      }
    };
    events.publish("preProcessText", payload);
    text = payload.text;
    options = payload.options;
    angle = options.angle;
    if (
      transformationMatrix instanceof Matrix === false &&
      angle &&
      typeof angle === "number"
    ) {
      angle *= Math.PI / 180;
      if (options.rotationDirection === 0) {
        angle = -angle;
      }
      if (apiMode === ApiMode.ADVANCED) {
        angle = -angle;
      }
      var c = Math.cos(angle);
      var s = Math.sin(angle);
      transformationMatrix = new Matrix(c, s, -s, c, 0, 0);
    } else if (angle && angle instanceof Matrix) {
      transformationMatrix = angle;
    }
    if (apiMode === ApiMode.ADVANCED && !transformationMatrix) {
      transformationMatrix = identityMatrix;
    }
    charSpace = options.charSpace || activeCharSpace;
    if (typeof charSpace !== "undefined") {
      xtra += hpf(scale(charSpace)) + " Tc\n";
      this.setCharSpace(this.getCharSpace() || 0);
    }
    horizontalScale = options.horizontalScale;
    if (typeof horizontalScale !== "undefined") {
      xtra += hpf(horizontalScale * 100) + " Tz\n";
    }
    var lang = options.lang;

    if (lang) {
    }
    var renderingMode = -1;
    var parmRenderingMode =
      typeof options.renderingMode !== "undefined"
        ? options.renderingMode
        : options.stroke;
    var pageContext = scope.internal.getCurrentPageInfo().pageContext;

    switch (parmRenderingMode) {
      case 0:
      case false:
      case "fill":
        renderingMode = 0;
        break;
      case 1:
      case true:
      case "stroke":
        renderingMode = 1;
        break;
      case 2:
      case "fillThenStroke":
        renderingMode = 2;
        break;
      case 3:
      case "invisible":
        renderingMode = 3;
        break;
      case 4:
      case "fillAndAddForClipping":
        renderingMode = 4;
        break;
      case 5:
      case "strokeAndAddPathForClipping":
        renderingMode = 5;
        break;
      case 6:
      case "fillThenStrokeAndAddToPathForClipping":
        renderingMode = 6;
        break;
      case 7:
      case "addToPathForClipping":
        renderingMode = 7;
        break;
    }
    var usedRenderingMode =
      typeof pageContext.usedRenderingMode !== "undefined"
        ? pageContext.usedRenderingMode
        : -1;
    if (renderingMode !== -1) {
      xtra += renderingMode + " Tr\n";

    } else if (usedRenderingMode !== -1) {
      xtra += "0 Tr\n";
    }
    if (renderingMode !== -1) {
      pageContext.usedRenderingMode = renderingMode;
    }
    align = options.align || "left";
    var leading = activeFontSize * lineHeight;
    var pageWidth = scope.internal.pageSize.getWidth();
    var activeFont = fonts[activeFontKey];
    charSpace = options.charSpace || activeCharSpace;
    maxWidth = options.maxWidth || 0;
    var lineWidths;
    flags = Object.assign({ autoencode: true, noBOM: true }, options.flags);
    var wordSpacingPerLine = [];
    if (Object.prototype.toString.call(text) === "[object Array]") {
      da = transformTextToSpecialArray(text);
      var newY;
      if (align !== "left") {
        lineWidths = da.map(function(v) {
          return (
            (scope.getStringUnitWidth(v, {
              font: activeFont,
              charSpace: charSpace,
              fontSize: activeFontSize,
              doKerning: false
            }) *
              activeFontSize) /
            scaleFactor
          );
        });
      }
      var prevWidth = 0;
      var newX;
      if (align === "right") {
        x -= lineWidths[0];
        text = [];
        len = da.length;
        for (var i = 0; i < len; i++) {
          if (i === 0) {
            newX = getHorizontalCoordinate(x);
            newY = getVerticalCoordinate(y);
          } else {
            newX = scale(prevWidth - lineWidths[i]);
            newY = -leading;
          }
          text.push([da[i], newX, newY]);
          prevWidth = lineWidths[i];
        }
      } else if (align === "center") {

        x -= lineWidths[0] / 2;
        text = [];
        len = da.length;
        for (var j = 0; j < len; j++) {
          if (j === 0) {
            newX = getHorizontalCoordinate(x);
            newY = getVerticalCoordinate(y);
          } else {
            newX = scale((prevWidth - lineWidths[j]) / 2);
            newY = -leading;
          }
          text.push([da[j], newX, newY]);
          prevWidth = lineWidths[j];
        }
      } else if (align === "left") {
        text = [];
        len = da.length;
        for (var h = 0; h < len; h++) {
          text.push(da[h]);
        }
      } else if (align === "justify") {
        text = [];
        len = da.length;
        maxWidth = maxWidth !== 0 ? maxWidth : pageWidth;

        for (var l = 0; l < len; l++) {
          newY = l === 0 ? getVerticalCoordinate(y) : -leading;
          newX = l === 0 ? getHorizontalCoordinate(x) : 0;
          if (l < len - 1) {
            wordSpacingPerLine.push(
              hpf(
                scale(
                  (maxWidth - lineWidths[l]) / (da[l].split(" ").length - 1)
                )
              )
            );
          } else {
            wordSpacingPerLine.push(0);
          }
          text.push([da[l], newX, newY]);
        }
      } else {
        throw new Error(
          'Unrecognized alignment option, use "left", "center", "right" or "justify".'
        );
      }
    }
    var doReversing = typeof options.R2L === "boolean" ? options.R2L : R2L;
    if (doReversing === true) {
      text = processTextByFunction(text, function(text, posX, posY) {
        return [
          text
            .split("")
            .reverse()
            .join(""),
          posX,
          posY
        ];
      });
    }
    payload = {
      text: text,
      x: x,
      y: y,
      options: options,
      mutex: {
        pdfEscape: pdfEscape,
        activeFontKey: activeFontKey,
        fonts: fonts,
        activeFontSize: activeFontSize
      }
    };
    events.publish("postProcessText", payload);
    text = payload.text;
    isHex = payload.mutex.isHex || false;
    var activeFontEncoding = fonts[activeFontKey].encoding;
    if (
      activeFontEncoding === "WinAnsiEncoding" ||
      activeFontEncoding === "StandardEncoding"
    ) {
      text = processTextByFunction(text, function(text, posX, posY) {
        return [ESC(text), posX, posY];
      });
    }
    da = transformTextToSpecialArray(text);
    text = [];
    var STRING = 0;
    var ARRAY = 1;
    var variant = Array.isArray(da[0]) ? ARRAY : STRING;
    var posX;
    var posY;
    var content;
    var wordSpacing = "";
    var generatePosition = function(
      parmPosX,
      parmPosY,
      parmTransformationMatrix
    ) {
      var position = "";
      if (parmTransformationMatrix instanceof Matrix) {
        if (typeof options.angle === "number") {
          parmTransformationMatrix = matrixMult(
            parmTransformationMatrix,
            new Matrix(1, 0, 0, 1, parmPosX, parmPosY)
          );
        } else {
          parmTransformationMatrix = matrixMult(
            new Matrix(1, 0, 0, 1, parmPosX, parmPosY),
            parmTransformationMatrix
          );
        }
        if (apiMode === ApiMode.ADVANCED) {
          parmTransformationMatrix = matrixMult(
            new Matrix(1, 0, 0, -1, 0, 0),
            parmTransformationMatrix
          );
        }
        position = parmTransformationMatrix.join(" ") + " Tm\n";
      } else {
        position = hpf(parmPosX) + " " + hpf(parmPosY) + " Td\n";
      }
      return position;
    };

    for (var lineIndex = 0; lineIndex < da.length; lineIndex++) {
      wordSpacing = "";

      switch (variant) {
        case ARRAY:
          content =
            (isHex ? "<" : "(") + da[lineIndex][0] + (isHex ? ">" : ")");
          posX = parseFloat(da[lineIndex][1]);
          posY = parseFloat(da[lineIndex][2]);
          break;
        case STRING:
          content = (isHex ? "<" : "(") + da[lineIndex] + (isHex ? ">" : ")");
          posX = getHorizontalCoordinate(x);
          posY = getVerticalCoordinate(y);
          break;
      }
      if (
        typeof wordSpacingPerLine !== "undefined" &&
        typeof wordSpacingPerLine[lineIndex] !== "undefined"
      ) {
        wordSpacing = wordSpacingPerLine[lineIndex] + " Tw\n";
      }
      if (lineIndex === 0) {
        text.push(
          wordSpacing +
            generatePosition(posX, posY, transformationMatrix) +
            content
        );
      } else if (variant === STRING) {
        text.push(wordSpacing + content);
      } else if (variant === ARRAY) {
        text.push(
          wordSpacing +
            generatePosition(posX, posY, transformationMatrix) +
            content
        );
      }
    }

    text = variant === STRING ? text.join(" Tj\nT* ") : text.join(" Tj\n");
    text += " Tj\n";

    var result = "BT\n/";
    result += activeFontKey + " " + activeFontSize + " Tf\n";
    result += hpf(activeFontSize * lineHeight) + " TL\n";
    result += textColor + "\n";
    result += xtra;
    result += text;
    result += "ET";
    out(result);
    usedFonts[activeFontKey] = true;
    return scope;
  };
  var clip = (API.__private__.clip = API.clip = function(rule) {
    if ("evenodd" === rule) {
      out("W*");
    } else {
      out("W");
    }
    return this;
  });
  API.clipEvenOdd = function() {
    return clip("evenodd");
  };
  API.__private__.discardPath = API.discardPath = function() {
    out("n");
    return this;
  };
  var isValidStyle = (API.__private__.isValidStyle = function(style) {
    var validStyleVariants = [
      undefined,
      null,
      "S",
      "D",
      "F",
      "DF",
      "FD",
      "f",
      "f*",
      "B",
      "B*",
      "n"
    ];
    var result = false;
    if (validStyleVariants.indexOf(style) !== -1) {
      result = true;
    }
    return result;
  });
  API.__private__.setDefaultPathOperation = API.setDefaultPathOperation = function(
    operator
  ) {
    if (isValidStyle(operator)) {
      defaultPathOperation = operator;
    }
    return this;
  };
  var getStyle = (API.__private__.getStyle = API.getStyle = function(style) {
    var op = defaultPathOperation;
    switch (style) {
      case "D":
      case "S":
        op = "S";
        break;
      case "F":
        op = "f";
        break;
      case "FD":
      case "DF":
        op = "B";
        break;
      case "f":
      case "f*":
      case "B":
      case "B*":
        op = style;
        break;
    }
    return op;
  });
  var close = (API.close = function() {
    out("h");
    return this;
  });
  API.stroke = function() {
    out("S");
    return this;
  };
  API.fill = function(pattern) {
    fillWithOptionalPattern("f", pattern);
    return this;
  };
  API.fillEvenOdd = function(pattern) {
    fillWithOptionalPattern("f*", pattern);
    return this;
  };
  API.fillStroke = function(pattern) {
    fillWithOptionalPattern("B", pattern);
    return this;
  };
  API.fillStrokeEvenOdd = function(pattern) {
    fillWithOptionalPattern("B*", pattern);
    return this;
  };
  var fillWithOptionalPattern = function(style, pattern) {
    if (typeof pattern === "object") {
      fillWithPattern(pattern, style);
    } else {
      out(style);
    }
  };
  var putStyle = function(style) {
    if (
      style === null ||
      (apiMode === ApiMode.ADVANCED && style === undefined)
    ) {
      return;
    }
    style = getStyle(style);
    out(style);
  };
  function cloneTilingPattern(patternKey, boundingBox, xStep, yStep, matrix) {
    var clone = new TilingPattern(
      boundingBox || this.boundingBox,
      xStep || this.xStep,
      yStep || this.yStep,
      this.gState,
      matrix || this.matrix
    );
    clone.stream = this.stream;
    var key = patternKey + "$$" + this.cloneIndex++ + "$$";
    addPattern(key, clone);
    return clone;
  }
  var fillWithPattern = function(patternData, style) {
    var patternId = patternMap[patternData.key];
    var pattern = patterns[patternId];
    if (pattern instanceof ShadingPattern) {
      out("q");
      out(clipRuleFromStyle(style));
      if (pattern.gState) {
        API.setGState(pattern.gState);
      }
      out(patternData.matrix.toString() + " cm");
      out("/" + patternId + " sh");
      out("Q");
    } else if (pattern instanceof TilingPattern) {
      var matrix = new Matrix(1, 0, 0, -1, 0, getPageHeight());

      if (patternData.matrix) {
        matrix = matrix.multiply(patternData.matrix || identityMatrix);
        patternId = cloneTilingPattern.call(
          pattern,
          patternData.key,
          patternData.boundingBox,
          patternData.xStep,
          patternData.yStep,
          matrix
        ).id;
      }
      out("q");
      out("/Pattern cs");
      out("/" + patternId + " scn");

      if (pattern.gState) {
        API.setGState(pattern.gState);
      }
      out(style);
      out("Q");
    }
  };
  var clipRuleFromStyle = function(style) {
    switch (style) {
      case "f":
      case "F":
        return "W n";
      case "f*":
        return "W* n";
      case "B":
        return "W S";
      case "B*":
        return "W* S";
      case "S":
        return "W S";
      case "n":
        return "W n";
    }
  };
  var moveTo = (API.moveTo = function(x, y) {
    out(hpf(scale(x)) + " " + hpf(transformScaleY(y)) + " m");
    return this;
  });
  var lineTo = (API.lineTo = function(x, y) {
    out(hpf(scale(x)) + " " + hpf(transformScaleY(y)) + " l");
    return this;
  });
  var curveTo = (API.curveTo = function(x1, y1, x2, y2, x3, y3) {
    out(
      [
        hpf(scale(x1)),
        hpf(transformScaleY(y1)),
        hpf(scale(x2)),
        hpf(transformScaleY(y2)),
        hpf(scale(x3)),
        hpf(transformScaleY(y3)),
        "c"
      ].join(" ")
    );
    return this;
  });
  API.__private__.line = API.line = function(x1, y1, x2, y2, style) {
    if (
      isNaN(x1) ||
      isNaN(y1) ||
      isNaN(x2) ||
      isNaN(y2) ||
      !isValidStyle(style)
    ) {
      throw new Error("Invalid arguments passed to jsPDF.line");
    }
    if (apiMode === ApiMode.COMPAT) {
      return this.lines([[x2 - x1, y2 - y1]], x1, y1, [1, 1], style || "S");
    } else {
      return this.lines([[x2 - x1, y2 - y1]], x1, y1, [1, 1]).stroke();
    }
  };
  API.__private__.lines = API.lines = function(
    lines,
    x,
    y,
    scale,
    style,
    closed
  ) {
    var scalex, scaley, i, l, leg, x2, y2, x3, y3, x4, y4, tmp;
    if (typeof lines === "number") {
      tmp = y;
      y = x;
      x = lines;
      lines = tmp;
    }
    scale = scale || [1, 1];
    closed = closed || false;
    if (
      isNaN(x) ||
      isNaN(y) ||
      !Array.isArray(lines) ||
      !Array.isArray(scale) ||
      !isValidStyle(style) ||
      typeof closed !== "boolean"
    ) {
      throw new Error("Invalid arguments passed to jsPDF.lines");
    }
    moveTo(x, y);
    scalex = scale[0];
    scaley = scale[1];
    l = lines.length;
    x4 = x;
    y4 = y;
    for (i = 0; i < l; i++) {
      leg = lines[i];
      if (leg.length === 2) {
        x4 = leg[0] * scalex + x4;
        y4 = leg[1] * scaley + y4;
        lineTo(x4, y4);
      } else {
        x2 = leg[0] * scalex + x4;
        y2 = leg[1] * scaley + y4;
        x3 = leg[2] * scalex + x4;
        y3 = leg[3] * scaley + y4;
        x4 = leg[4] * scalex + x4;
        y4 = leg[5] * scaley + y4;
        curveTo(x2, y2, x3, y3, x4, y4);
      }
    }
    if (closed) {
      close();
    }
    putStyle(style);
    return this;
  };
  API.path = function(lines) {
    for (var i = 0; i < lines.length; i++) {
      var leg = lines[i];
      var coords = leg.c;
      switch (leg.op) {
        case "m":
          moveTo(coords[0], coords[1]);
          break;
        case "l":
          lineTo(coords[0], coords[1]);
          break;
        case "c":
          curveTo.apply(this, coords);
          break;
        case "h":
          close();
          break;
      }
    }
    return this;
  };
  API.__private__.rect = API.rect = function(x, y, w, h, style) {
    if (isNaN(x) || isNaN(y) || isNaN(w) || isNaN(h) || !isValidStyle(style)) {
      throw new Error("Invalid arguments passed to jsPDF.rect");
    }
    if (apiMode === ApiMode.COMPAT) {
      h = -h;
    }
    out(
      [
        hpf(scale(x)),
        hpf(transformScaleY(y)),
        hpf(scale(w)),
        hpf(scale(h)),
        "re"
      ].join(" ")
    );
    putStyle(style);
    return this;
  };
  API.__private__.triangle = API.triangle = function(
    x1,
    y1,
    x2,
    y2,
    x3,
    y3,
    style
  ) {
    if (
      isNaN(x1) ||
      isNaN(y1) ||
      isNaN(x2) ||
      isNaN(y2) ||
      isNaN(x3) ||
      isNaN(y3) ||
      !isValidStyle(style)
    ) {
      throw new Error("Invalid arguments passed to jsPDF.triangle");
    }
    this.lines(
      [
        [x2 - x1, y2 - y1],
        [x3 - x2, y3 - y2],
        [x1 - x3, y1 - y3]
      ],
      x1,
      y1,
      [1, 1],
      style,
      true
    );
    return this;
  };
  API.__private__.roundedRect = API.roundedRect = function(
    x,
    y,
    w,
    h,
    rx,
    ry,
    style
  ) {
    if (
      isNaN(x) ||
      isNaN(y) ||
      isNaN(w) ||
      isNaN(h) ||
      isNaN(rx) ||
      isNaN(ry) ||
      !isValidStyle(style)
    ) {
      throw new Error("Invalid arguments passed to jsPDF.roundedRect");
    }
    var MyArc = (4 / 3) * (Math.SQRT2 - 1);
    rx = Math.min(rx, w * 0.5);
    ry = Math.min(ry, h * 0.5);
    this.lines(
      [
        [w - 2 * rx, 0],
        [rx * MyArc, 0, rx, ry - ry * MyArc, rx, ry],
        [0, h - 2 * ry],
        [0, ry * MyArc, -(rx * MyArc), ry, -rx, ry],
        [-w + 2 * rx, 0],
        [-(rx * MyArc), 0, -rx, -(ry * MyArc), -rx, -ry],
        [0, -h + 2 * ry],
        [0, -(ry * MyArc), rx * MyArc, -ry, rx, -ry]
      ],
      x + rx,
      y,
      [1, 1],
      style,
      true
    );
    return this;
  };
  API.__private__.ellipse = API.ellipse = function(x, y, rx, ry, style) {
    if (
      isNaN(x) ||
      isNaN(y) ||
      isNaN(rx) ||
      isNaN(ry) ||
      !isValidStyle(style)
    ) {
      throw new Error("Invalid arguments passed to jsPDF.ellipse");
    }
    var lx = (4 / 3) * (Math.SQRT2 - 1) * rx,
      ly = (4 / 3) * (Math.SQRT2 - 1) * ry;
    moveTo(x + rx, y);
    curveTo(x + rx, y - ly, x + lx, y - ry, x, y - ry);
    curveTo(x - lx, y - ry, x - rx, y - ly, x - rx, y);
    curveTo(x - rx, y + ly, x - lx, y + ry, x, y + ry);
    curveTo(x + lx, y + ry, x + rx, y + ly, x + rx, y);

    putStyle(style);
    return this;
  };
  API.__private__.circle = API.circle = function(x, y, r, style) {
    if (isNaN(x) || isNaN(y) || isNaN(r) || !isValidStyle(style)) {
      throw new Error("Invalid arguments passed to jsPDF.circle");
    }
    return this.ellipse(x, y, r, r, style);
  };
  API.setFont = function(fontName, fontStyle, fontWeight) {
    if (fontWeight) {
      fontStyle = combineFontStyleAndFontWeight(fontStyle, fontWeight);
    }
    activeFontKey = getFont(fontName, fontStyle, {
      disableWarning: false
    });
    return this;
  };
  var getFontEntry = (API.__private__.getFont = API.getFont = function() {
    return fonts[getFont.apply(API, arguments)];
  });

  API.__private__.getFontList = API.getFontList = function() {
    var list = {},
      fontName,
      fontStyle;

    for (fontName in fontmap) {
      if (fontmap.hasOwnProperty(fontName)) {
        list[fontName] = [];
        for (fontStyle in fontmap[fontName]) {
          if (fontmap[fontName].hasOwnProperty(fontStyle)) {
            list[fontName].push(fontStyle);
          }
        }
      }
    }
    return list;
  };

  API.addFont = function(
    postScriptName,
    fontName,
    fontStyle,
    fontWeight,
    encoding
  ) {
    var encodingOptions = [
      "StandardEncoding",
      "MacRomanEncoding",
      "Identity-H",
      "WinAnsiEncoding"
    ];
    if (arguments[3] && encodingOptions.indexOf(arguments[3]) !== -1) {
      encoding = arguments[3];
    } else if (arguments[3] && encodingOptions.indexOf(arguments[3]) == -1) {
      fontStyle = combineFontStyleAndFontWeight(fontStyle, fontWeight);
    }
    encoding = encoding || "Identity-H";
    return addFont.call(this, postScriptName, fontName, fontStyle, encoding);
  };

  var lineWidth = options.lineWidth || 0.200025; // 2mm

  var getLineWidth = (API.__private__.getLineWidth = API.getLineWidth = function() {
    return lineWidth;
  });

  var setLineWidth = (API.__private__.setLineWidth = API.setLineWidth = function(
    width
  ) {
    lineWidth = width;
    out(hpf(scale(width)) + " w");
    return this;
  });

  API.__private__.setLineDash = jsPDF.API.setLineDash = jsPDF.API.setLineDashPattern = function(
    dashArray,
    dashPhase
  ) {
    dashArray = dashArray || [];
    dashPhase = dashPhase || 0;

    if (isNaN(dashPhase) || !Array.isArray(dashArray)) {
      throw new Error("Invalid arguments passed to jsPDF.setLineDash");
    }

    dashArray = dashArray
      .map(function(x) {
        return hpf(scale(x));
      })
      .join(" ");
    dashPhase = hpf(scale(dashPhase));

    out("[" + dashArray + "] " + dashPhase + " d");
    return this;
  };

  var lineHeightFactor;

  var getLineHeight = (API.__private__.getLineHeight = API.getLineHeight = function() {
    return activeFontSize * lineHeightFactor;
  });

  API.__private__.getLineHeight = API.getLineHeight = function() {
    return activeFontSize * lineHeightFactor;
  };

  var setLineHeightFactor = (API.__private__.setLineHeightFactor = API.setLineHeightFactor = function(
    value
  ) {
    value = value || 1.15;
    if (typeof value === "number") {
      lineHeightFactor = value;
    }
    return this;
  });
  var getLineHeightFactor = (API.__private__.getLineHeightFactor = API.getLineHeightFactor = function() {
    return lineHeightFactor;
  });
  setLineHeightFactor(options.lineHeight);
  var getHorizontalCoordinate = (API.__private__.getHorizontalCoordinate = function(
    value
  ) {
    return scale(value);
  });
  var getVerticalCoordinate = (API.__private__.getVerticalCoordinate = function(
    value
  ) {
    if (apiMode === ApiMode.ADVANCED) {
      return value;
    } else {
      var pageHeight =
        pagesContext[currentPage].mediaBox.topRightY -
        pagesContext[currentPage].mediaBox.bottomLeftY;
      return pageHeight - scale(value);
    }
  });
  var getHorizontalCoordinateString = (API.__private__.getHorizontalCoordinateString = API.getHorizontalCoordinateString = function(
    value
  ) {
    return hpf(getHorizontalCoordinate(value));
  });
  var getVerticalCoordinateString = (API.__private__.getVerticalCoordinateString = API.getVerticalCoordinateString = function(
    value
  ) {
    return hpf(getVerticalCoordinate(value));
  });
  var strokeColor = options.strokeColor || "0 G";
  API.__private__.getStrokeColor = API.getDrawColor = function() {
    return decodeColorString(strokeColor);
  };
  API.__private__.setStrokeColor = API.setDrawColor = function(
    ch1,
    ch2,
    ch3,
    ch4
  ) {
    var options = {
      ch1: ch1,
      ch2: ch2,
      ch3: ch3,
      ch4: ch4,
      pdfColorType: "draw",
      precision: 2
    };
    strokeColor = encodeColorString(options);
    out(strokeColor);
    return this;
  };
  var fillColor = options.fillColor || "0 g";
  API.__private__.getFillColor = API.getFillColor = function() {
    return decodeColorString(fillColor);
  };
  API.__private__.setFillColor = API.setFillColor = function(
    ch1,
    ch2,
    ch3,
    ch4
  ) {
    var options = {
      ch1: ch1,
      ch2: ch2,
      ch3: ch3,
      ch4: ch4,
      pdfColorType: "fill",
      precision: 2
    };

    fillColor = encodeColorString(options);
    out(fillColor);
    return this;
  };
  var textColor = options.textColor || "0 g";
  var getTextColor = (API.__private__.getTextColor = API.getTextColor = function() {
    return decodeColorString(textColor);
  });
  API.__private__.setTextColor = API.setTextColor = function(
    ch1,
    ch2,
    ch3,
    ch4
  ) {
    var options = {
      ch1: ch1,
      ch2: ch2,
      ch3: ch3,
      ch4: ch4,
      pdfColorType: "text",
      precision: 3
    };
    textColor = encodeColorString(options);

    return this;
  };

  var activeCharSpace = options.charSpace;

  var getCharSpace = (API.__private__.getCharSpace = API.getCharSpace = function() {
    return parseFloat(activeCharSpace || 0);
  });

  API.__private__.setCharSpace = API.setCharSpace = function(charSpace) {
    if (isNaN(charSpace)) {
      throw new Error("Invalid argument passed to jsPDF.setCharSpace");
    }
    activeCharSpace = charSpace;
    return this;
  };

  var lineCapID = 0;
  
  API.CapJoinStyles = {
    0: 0,
    butt: 0,
    but: 0,
    miter: 0,
    1: 1,
    round: 1,
    rounded: 1,
    circle: 1,
    2: 2,
    projecting: 2,
    project: 2,
    square: 2,
    bevel: 2
  };
  API.__private__.setLineCap = API.setLineCap = function(style) {
    var id = API.CapJoinStyles[style];
    if (id === undefined) {
      throw new Error(
        "Line cap style of '" +
          style +
          "' is not recognized. See or extend .CapJoinStyles property for valid styles"
      );
    }
    lineCapID = id;
    out(id + " J");
    return this;
  };
  var lineJoinID = 0;
  API.__private__.setLineJoin = API.setLineJoin = function(style) {
    var id = API.CapJoinStyles[style];
    if (id === undefined) {
      throw new Error(
        "Line join style of '" +
          style +
          "' is not recognized. See or extend .CapJoinStyles property for valid styles"
      );
    }
    lineJoinID = id;
    out(id + " j");

    return this;
  };
  var miterLimit;
  API.__private__.setLineMiterLimit = API.__private__.setMiterLimit = API.setLineMiterLimit = API.setMiterLimit = function(
    length
  ) {
    length = length || 0;
    if (isNaN(length)) {
      throw new Error("Invalid argument passed to jsPDF.setLineMiterLimit");
    }
    out(hpf(scale(length)) + " M");
    return this;
  };
  API.GState = GState;
  API.setGState = function(gState) {
    if (typeof gState === "string") {
      gState = gStates[gStatesMap[gState]];
    } else {
      gState = addGState(null, gState);
    }
    if (!gState.equals(activeGState)) {
      out("/" + gState.id + " gs");
      activeGState = gState;
    }
  };

  var addGState = function(key, gState) {
    if (key && gStatesMap[key]) return;
    var duplicate = false;
    for (var s in gStates) {
      if (gStates.hasOwnProperty(s)) {
        if (gStates[s].equals(gState)) {
          duplicate = true;
          break;
        }
      }
    }
    if (duplicate) {
      gState = gStates[s];
    } else {
      var gStateKey = "GS" + (Object.keys(gStates).length + 1).toString(10);
      gStates[gStateKey] = gState;
      gState.id = gStateKey;
    }
    key && (gStatesMap[key] = gState.id);
    events.publish("addGState", gState);
    return gState;
  };
  API.addGState = function(key, gState) {
    addGState(key, gState);
    return this;
  };
  API.saveGraphicsState = function() {
    out("q");
    fontStateStack.push({
      key: activeFontKey,
      size: activeFontSize,
      color: textColor
    });
    return this;
  };
  API.restoreGraphicsState = function() {
    out("Q");
    var fontState = fontStateStack.pop();
    activeFontKey = fontState.key;
    activeFontSize = fontState.size;
    textColor = fontState.color;
    activeGState = null;
    return this;
  };
  API.setCurrentTransformationMatrix = function(matrix) {
    out(matrix.toString() + " cm");
    return this;
  };
  API.comment = function(text) {
    out("#" + text);
    return this;
  };
  var Point = function(x, y) {
    var _x = x || 0;
    Object.defineProperty(this, "x", {
      enumerable: true,
      get: function() {
        return _x;
      },
      set: function(value) {
        if (!isNaN(value)) {
          _x = parseFloat(value);
        }
      }
    });
    var _y = y || 0;
    Object.defineProperty(this, "y", {
      enumerable: true,
      get: function() {
        return _y;
      },
      set: function(value) {
        if (!isNaN(value)) {
          _y = parseFloat(value);
        }
      }
    });
    var _type = "pt";
    Object.defineProperty(this, "type", {
      enumerable: true,
      get: function() {
        return _type;
      },
      set: function(value) {
        _type = value.toString();
      }
    });
    return this;
  };
  var Rectangle = function(x, y, w, h) {
    Point.call(this, x, y);
    this.type = "rect";
    var _w = w || 0;
    Object.defineProperty(this, "w", {
      enumerable: true,
      get: function() {
        return _w;
      },
      set: function(value) {
        if (!isNaN(value)) {
          _w = parseFloat(value);
        }
      }
    });
    var _h = h || 0;
    Object.defineProperty(this, "h", {
      enumerable: true,
      get: function() {
        return _h;
      },
      set: function(value) {
        if (!isNaN(value)) {
          _h = parseFloat(value);
        }
      }
    });
    return this;
  };
  var RenderTarget = function() {
    this.page = page;
    this.currentPage = currentPage;
    this.pages = pages.slice(0);
    this.pagesContext = pagesContext.slice(0);
    this.x = pageX;
    this.y = pageY;
    this.matrix = pageMatrix;
    this.width = getPageWidth(currentPage);
    this.height = getPageHeight(currentPage);
    this.outputDestination = outputDestination;

    this.id = "";
    this.objectNumber = -1;
  };
  RenderTarget.prototype.restore = function() {
    page = this.page;
    currentPage = this.currentPage;
    pagesContext = this.pagesContext;
    pages = this.pages;
    pageX = this.x;
    pageY = this.y;
    pageMatrix = this.matrix;
    setPageWidth(currentPage, this.width);
    setPageHeight(currentPage, this.height);
    outputDestination = this.outputDestination;
  };
  var beginNewRenderTarget = function(x, y, width, height, matrix) {
    renderTargetStack.push(new RenderTarget());
    page = currentPage = 0;
    pages = [];
    pageX = x;
    pageY = y;
    pageMatrix = matrix;
    beginPage([width, height]);
  };
  var endFormObject = function(key) {
    if (renderTargetMap[key]) {
      renderTargetStack.pop().restore();
      return;
    }
    var newXObject = new RenderTarget();
    var xObjectId = "Xo" + (Object.keys(renderTargets).length + 1).toString(10);
    newXObject.id = xObjectId;
    renderTargetMap[key] = xObjectId;
    renderTargets[xObjectId] = newXObject;
    events.publish("addFormObject", newXObject);
    renderTargetStack.pop().restore();
  };
  API.beginFormObject = function(x, y, width, height, matrix) {
    beginNewRenderTarget(x, y, width, height, matrix);
    return this;
  };
  API.endFormObject = function(key) {
    endFormObject(key);
    return this;
  };
  API.doFormObject = function(key, matrix) {
    var xObject = renderTargets[renderTargetMap[key]];
    out("q");
    out(matrix.toString() + " cm");
    out("/" + xObject.id + " Do");
    out("Q");
    return this;
  };

  API.getFormObject = function(key) {
    var xObject = renderTargets[renderTargetMap[key]];
    return {
      x: xObject.x,
      y: xObject.y,
      width: xObject.width,
      height: xObject.height,
      matrix: xObject.matrix
    };
  };
  API.save = function(filename, options) {
    filename = filename || "generated.pdf";
    options = options || {};
    options.returnPromise = options.returnPromise || false;
    if (options.returnPromise === false) {
      saveAs(getBlob(buildDocument()), filename);
      if (typeof saveAs.unload === "function") {
        if (globalObject.setTimeout) {
          setTimeout(saveAs.unload, 911);
        }
      }
      return this;
    } else {
      return new Promise(function(resolve, reject) {
        try {
          var result = saveAs(getBlob(buildDocument()), filename);
          if (typeof saveAs.unload === "function") {
            if (globalObject.setTimeout) {
              setTimeout(saveAs.unload, 911);
            }
          }
          resolve(result);
        } catch (e) {
          reject(e.message);
        }
      });
    }
    // @endif

    var fs = require("fs");
    var buffer = Buffer.from(getArrayBuffer(buildDocument()));
    if (options.returnPromise === false) {
      fs.writeFileSync(filename, buffer);
    } else {
      return new Promise(function(resolve, reject) {
        fs.writeFile(filename, buffer, function(err) {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    }
    // @endif
  };
  for (var plugin in jsPDF.API) {
    if (jsPDF.API.hasOwnProperty(plugin)) {
      if (plugin === "events" && jsPDF.API.events.length) {
        (function(events, newEvents) {
          var eventname, handler_and_args, i;

          for (i = newEvents.length - 1; i !== -1; i--) {
            eventname = newEvents[i][0];
            handler_and_args = newEvents[i][1];
            events.subscribe.apply(
              events,
              [eventname].concat(
                typeof handler_and_args === "function"
                  ? [handler_and_args]
                  : handler_and_args
              )
            );
          }
        })(events, jsPDF.API.events);
      } else {
        API[plugin] = jsPDF.API[plugin];
      }
    }
  }

  var getPageWidth = (API.getPageWidth = function(pageNumber) {
    pageNumber = pageNumber || currentPage;
    return (
      (pagesContext[pageNumber].mediaBox.topRightX -
        pagesContext[pageNumber].mediaBox.bottomLeftX) /
      scaleFactor
    );
  });

  var setPageWidth = (API.setPageWidth = function(pageNumber, value) {
    pagesContext[pageNumber].mediaBox.topRightX =
      value * scaleFactor + pagesContext[pageNumber].mediaBox.bottomLeftX;
  });

  var getPageHeight = (API.getPageHeight = function(pageNumber) {
    pageNumber = pageNumber || currentPage;
    return (
      (pagesContext[pageNumber].mediaBox.topRightY -
        pagesContext[pageNumber].mediaBox.bottomLeftY) /
      scaleFactor
    );
  });
  var setPageHeight = (API.setPageHeight = function(pageNumber, value) {
    pagesContext[pageNumber].mediaBox.topRightY =
      value * scaleFactor + pagesContext[pageNumber].mediaBox.bottomLeftY;
  });
  ///////////////////////////////////////
  API.loadFile = function(url, sync, callback) {
    console.log('entro a loadFile');
    sync = sync === false ? false : true;
    callback = typeof callback === "function" ? callback : function() {};
    var result = undefined;
    var xhr = function(url, sync, callback) {
      var request = new XMLHttpRequest();
      var i = 0;
      var sanitizeUnicode = function(data) {
        var dataLength = data.length;
        var charArray = [];
        var StringFromCharCode = String.fromCharCode;
        //Transform Unicode to ASCII
        for (i = 0; i < dataLength; i += 1) {
          charArray.push(StringFromCharCode(data.charCodeAt(i) & 0xff));
        }
        return charArray.join("");
      };
      request.open("GET", url, !sync);
      // XHR binary charset opt by Marcus Granado 2006 [http://mgran.blogspot.com]
      request.overrideMimeType("text/plain; charset=x-user-defined");
      if (sync === false) {
        request.onload = function() {
          if (request.status === 200) {
            callback(sanitizeUnicode(this.responseText));
          } else {
            callback(undefined);
          }
        };
      }
      request.send(null);
      if (sync && request.status === 200) {
        return sanitizeUnicode(request.responseText);
      }
    };
    try {
      result = xhr(url, sync, callback);
      // eslint-disable-next-line no-empty
    } catch (e) {}
    return result;
  };
  /**
   * @name loadImageFile
   * @function
   * @param {string} path
   * @param {boolean} sync
   * @param {function} callback
   */
  API.loadImageFile = API.loadFile;

// API.addImage = addImage;

  ////////////////////////////
  API.internal = {
    pdfEscape: pdfEscape,
    getStyle: getStyle,
    getFont: getFontEntry,
    getFontSize: getFontSize,
    getCharSpace: getCharSpace,
    getTextColor: getTextColor,
    getLineHeight: getLineHeight,
    getLineHeightFactor: getLineHeightFactor,
    getLineWidth: getLineWidth,
    write: write,
    getHorizontalCoordinate: getHorizontalCoordinate,
    getVerticalCoordinate: getVerticalCoordinate,
    getCoordinateString: getHorizontalCoordinateString,
    getVerticalCoordinateString: getVerticalCoordinateString,
    collections: {},
    newObject: newObject,
    newAdditionalObject: newAdditionalObject,
    newObjectDeferred: newObjectDeferred,
    newObjectDeferredBegin: newObjectDeferredBegin,
    getFilters: getFilters,
    putStream: putStream,
    events: events,
    scaleFactor: scaleFactor,
    pageSize: {
      getWidth: function() {
        return getPageWidth(currentPage);
      },
      setWidth: function(value) {
        setPageWidth(currentPage, value);
      },
      getHeight: function() {
        return getPageHeight(currentPage);
      },
      setHeight: function(value) {
        setPageHeight(currentPage, value);
      }
    },
    encryptionOptions: encryptionOptions,
    encryption: encryption,
    getEncryptor: getEncryptor,
    output: output,
    getNumberOfPages: getNumberOfPages,
    pages: pages,
    out: out,
    f2: f2,
    f3: f3,
    getPageInfo: getPageInfo,
    getPageInfoByObjId: getPageInfoByObjId,
    getCurrentPageInfo: getCurrentPageInfo,
    getPDFVersion: getPdfVersion,
    Point: Point,
    Rectangle: Rectangle,
    Matrix: Matrix,
    hasHotfix: hasHotfix
  };
  Object.defineProperty(API.internal.pageSize, "width", {
    get: function() {
      return getPageWidth(currentPage);
    },
    set: function(value) {
      setPageWidth(currentPage, value);
    },
    enumerable: true,
    configurable: true
  });
  Object.defineProperty(API.internal.pageSize, "height", {
    get: function() {
      return getPageHeight(currentPage);
    },
    set: function(value) {
      setPageHeight(currentPage, value);
    },
    enumerable: true,
    configurable: true
  });
  addFonts.call(API, standardFonts);
  activeFontKey = "F1";
  _addPage(format, orientation);
  events.publish("initialized");
  return API;
}
jsPDF.API = {
  events: []
};
jsPDF.version = "0.0.0";
export { jsPDF, ShadingPattern, TilingPattern, GState };
export default jsPDF;