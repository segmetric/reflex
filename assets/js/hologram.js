import "core-js/stable";
import "regenerator-runtime/runtime"; 

// see: https://www.blazemeter.com/blog/the-correct-way-to-import-lodash-libraries-a-benchmark
import cloneDeep from "lodash/cloneDeep";

import Runtime from "./hologram/runtime"

export default class Hologram {
  // TODO: refactor & test
  static interpolate(value) {
    switch (value.type) {
      case "integer":
        return `${value.value}`
        
      case "string":
        return `${value.value}`
    }
  }

  // TODO: refactor & test
  static get_module(name) {
    return eval(name.replace(/\./g, ""))
  }

  // TODO: refactor & test
  static getRuntime() {
    if (!window.hologramRuntime) {
      window.hologramRuntime = new Runtime()
    }

    return window.hologramRuntime
  }

  // TODO: refactor & test
  static isPatternMatched(left, right) {
    let lType = left.type;
    let rType = right.type;

    if (lType != 'placeholder') {
      if (lType != rType) {
        return false;
      }

      if (lType == 'atom' && left.value != right.value) {
        return false;
      }
    }

    return true;
  }

  // TODO: refactor & test
  static js(js) {
    eval(js.value)
  }

  // TODO: refactor & test
  static objectKey(key) {
    switch (key.type) {
      case 'atom':
        return `~atom[${key.value}]`

      case 'string':
        return `~string[${key.value}]`
        
      default:
        throw 'Not implemented, at HologramPage.objectKey()'
    }
  }

  // TODO: refactor & test
  static onReady(document, callback) {
    if (
      document.readyState === "interactive" ||
      document.readyState === "complete"
    ) {
      callback();
    } else {
      document.addEventListener("DOMContentLoaded", function listener() {
        document.removeEventListener("DOMContentLoaded", listener);
        callback();
      });
    }
  }

  // TODO: refactor & test
  static patternMatchFunctionArgs(params, args) {
    if (args.length != params.length) {
      return false;
    }

    for (let i = 0; i < params.length; ++ i) {
      if (!Hologram.isPatternMatched(params[i], args[i])) {
        return false;
      }
    }

    return true;
  }

  // TODO: refactor & test
  static run(window, pageModule, state) {
    Hologram.onReady(window.document, () => {
      Hologram.getRuntime().handleNewPage(pageModule, state)
    })
  }
}

window.Elixir_Kernel = class {
  // TODO: refactor & test
  static $add(left, right) {
    let type = left.type == "integer" && right.type == "integer" ? "integer" : "float"
    return { type: type, value: left.value + right.value }
  }

  // TODO: refactor & test
  static $dot(left, right) {
    return cloneDeep(left.data[Hologram.objectKey(right)])
  }
}

window.Elixir_Map = class {
  // TODO: refactor & test
  static put(map, key, value) {
    let mapClone = cloneDeep(map)
    mapClone.data[Hologram.objectKey(key)] = value
    return mapClone;
  }
}

window.Hologram = Hologram