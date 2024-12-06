import birl
import gleam/int
import gleam/io
import gleam/list

pub fn timeit(fun: fn() -> a) -> a {
  let start = birl.now()
  let ret = fun()
  let end = birl.now()
  let duration = birl.to_unix_milli(end) - birl.to_unix_milli(start)
  io.println("Took " <> int.to_string(duration) <> "ms")
  ret
}

pub fn at_index(l: List(a), index: Int) -> Result(a, Nil) {
  case list.pop(l, fn(_) { True }) {
    Ok(#(first, rest)) -> {
      case index - 1 {
        0 -> Ok(first)
        _ -> at_index(rest, index - 1)
      }
    }
    Error(_) -> Error(Nil)
  }
}

pub fn defer(defer_func: fn() -> b, action: fn() -> a) -> a {
  let result = action()
  defer_func()
  result
}
