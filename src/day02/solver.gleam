import argv
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type InputType =
  List(List(Int))

fn read_lines(stream: FileStream, input: InputType) -> InputType {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let values =
        string.trim(line)
        |> string.split(" ")
        |> list.try_map(int.parse)
        |> result.unwrap([])
      read_lines(stream, [values, ..input])
    }
    _ -> input
  }
}

fn same_sign(a, b: Int) -> Bool {
  int.clamp(a, -1, 1) == int.clamp(b, -1, 1)
}

fn between(a, min, max: Int) -> Bool {
  min <= a && a <= max
}

fn is_safe(input: List(Int)) -> Bool {
  let diff = {
    use w <- list.map(list.window(input, 2))
    list.reduce(w, fn(a, b) { b - a }) |> result.unwrap(0)
  }

  list.all(diff, fn(d) {
    same_sign(result.unwrap(list.first(diff), 0), d)
    && between(int.absolute_value(d), 1, 3)
  })
}

fn pop_index(l: List(a), n: Int) -> List(a) {
  list.flatten([list.take(l, n), list.drop(l, n + 1)])
}

fn is_safe_rec(orig, input: List(Int), n: Int) -> Bool {
  is_safe(input)
  || n < list.length(orig)
  && is_safe_rec(orig, pop_index(orig, n), n + 1)
}

fn part_1(input: InputType) -> Int {
  list.count(input, is_safe)
}

fn part_2(input: InputType) -> Int {
  list.count(input, fn(i) { is_safe_rec(i, i, 0) })
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)
  let lines = read_lines(stream, [])

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
