import birl
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam_community/maths/elementary

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
      case index {
        0 -> Ok(first)
        _ -> at_index(rest, index - 1)
      }
    }
    Error(_) -> Error(Nil)
  }
}

pub fn n_digits(n: Int) -> Int {
  {
    int.to_float(n)
    |> elementary.logarithm_10()
    |> result.unwrap(0.0)
    |> float.floor()
    |> float.round()
  }
  + 1
}

pub fn split_int(n: Int, i: Int) -> #(Int, Int) {
  let pow = pow10(i)
  #(n / pow, n % pow)
}

pub fn pow10(n: Int) -> Int {
  int.power(10, int.to_float(n))
  |> result.unwrap(0.0)
  |> float.round()
}

pub fn concat_int(a: Int, b: Int) -> Int {
  a * pow10(n_digits(b)) + b
}

pub fn defer(defer_func: fn() -> b, action: fn() -> a) -> a {
  let result = action()
  defer_func()
  result
}
