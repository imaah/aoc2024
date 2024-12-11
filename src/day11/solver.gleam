import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import rememo/memo
import utils

type Input =
  List(Int)

fn read_lines(stream: FileStream) -> Input {
  case file_stream.read_line(stream) {
    Ok(line) ->
      string.trim(line)
      |> string.split(" ")
      |> list.filter_map(int.parse)
    _ -> []
  }
}

fn n_stones(n: Int, depth: Int, cache) -> Int {
  use <- memo.memoize(cache, #(n, depth))
  use <- bool.guard(depth == 0, 1)
  use <- bool.lazy_guard(n == 0, fn() { n_stones(1, depth - 1, cache) })

  case utils.n_digits(n) {
    s if s % 2 == 0 -> {
      let #(r, l) = utils.split_int(n, s / 2)
      n_stones(r, depth - 1, cache) + n_stones(l, depth - 1, cache)
    }
    _ -> n_stones(n * 2024, depth - 1, cache)
  }
}

fn part_1(input: Input, cache) -> Int {
  list.map(input, fn(v) { n_stones(v, 25, cache) })
  |> int.sum
}

fn part_2(input: Input, cache) -> Int {
  list.map(input, fn(v) { n_stones(v, 75, cache) })
  |> int.sum
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let lines = read_lines(stream)
  use cache <- memo.create()

  io.println("part1={" <> int.to_string(part_1(lines, cache)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines, cache)) <> "}")
}
