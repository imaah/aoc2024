import argv
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type InputLine {
  Line(value: Int, nums: List(Int))
}

type Input =
  List(InputLine)

fn read_lines(stream: FileStream, input: Input) -> Input {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let line =
        {
          use #(val, nums) <- result.try(string.split_once(line, ": "))
          use val <- result.try(int.parse(val))
          let nums =
            string.split(nums, " ")
            |> list.map(string.trim)
            |> list.filter_map(int.parse)
          Ok(Line(value: val, nums: nums))
        }
        |> result.lazy_unwrap(fn() { panic })
      read_lines(stream, [line, ..input])
    }

    _ -> input
  }
}

fn is_solvable(current: Int, line: InputLine) -> Bool {
  case line {
    Line(n, []) -> current == n
    Line(n, [first, ..rest]) ->
      is_solvable(current + first, Line(n, rest))
      || is_solvable(current * first, Line(n, rest))
  }
}

fn part_1(input: Input) -> Int {
  list.filter(input, fn(l) { is_solvable(0, l) })
  |> list.map(fn(v) { v.value })
  |> list.fold(0, fn(acc, v) { acc + v })
}

fn concat(a: Int, b: Int) -> Int {
  { int.to_string(a) <> int.to_string(b) }
  |> int.parse()
  |> result.unwrap(0)
}

fn is_solvable_with_concat(current: Int, line: InputLine) -> Bool {
  case line {
    Line(n, []) -> current == n
    Line(n, _) if current > n -> False
    Line(n, [first, ..rest]) ->
      is_solvable_with_concat(current + first, Line(n, rest))
      || is_solvable_with_concat(current * first, Line(n, rest))
      || is_solvable_with_concat(concat(current, first), Line(n, rest))
  }
}

fn part_2(input: Input) -> Int {
  list.filter(input, fn(l) { is_solvable_with_concat(0, l) })
  |> list.map(fn(v) { v.value })
  |> list.fold(0, fn(acc, v) { acc + v })
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)
  // use this line if the order of the input is important!
  // let lines = list.reverse(read_lines(stream, []))
  let lines = read_lines(stream, [])

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
