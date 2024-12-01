import argv
import file_streams/file_stream.{type FileStream}
import file_streams/file_stream_error
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type InputType =
  #(List(Int), List(Int))

fn read_lines(stream: FileStream, left, right: List(Int)) -> InputType {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let assert Ok(#(l, r)) = string.split_once(string.trim(line), on: "   ")
      let assert Ok(rval) = int.base_parse(r, 10)
      let assert Ok(lval) = int.base_parse(l, 10)
      read_lines(stream, [lval, ..left], [rval, ..right])
    }
    _ -> #(right, left)
  }
}

fn part_1(left, right: List(Int)) -> Int {
  let sr = list.sort(right, by: int.compare)
  let sl = list.sort(left, by: int.compare)

  let assert Ok(res) =
    list.map2(sr, sl, fn(a, b) { int.absolute_value(b - a) })
    |> list.reduce(fn(acc, v) { acc + v })
  res
}

fn dict_get_or_default(counter: Dict(Int, Int), key: Int) -> Int {
  case dict.get(counter, key) {
    Ok(count) -> count
    Error(_) -> 0
  }
}

fn part_2(left, right: List(Int)) -> Int {
  let counter =
    list.map(left, fn(v) { #(v, list.count(left, fn(a) { v == a })) })
    |> dict.from_list()

  let assert Ok(res) =
    list.map(right, fn(v) { v * dict_get_or_default(counter, v) })
    |> list.reduce(fn(acc, v) { acc + v })
  res
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    [] -> "input.txt"
  }

  let stream = case file_stream.open_read(filename) {
    Ok(s) -> s
    Error(err) -> {
      io.println_error("error: " <> file_stream_error.describe(err))
      panic
    }
  }

  let #(left, right) = read_lines(stream, [], [])

  io.println("part1={" <> int.to_string(part_1(left, right)) <> "}")
  io.println("part2={" <> int.to_string(part_2(left, right)) <> "}")
}
