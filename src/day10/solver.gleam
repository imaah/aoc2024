import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

type Input =
  List(List(Int))

fn read_lines(stream: FileStream) -> Input {
  case file_stream.read_line(stream) {
    Ok(line) -> [
      string.trim(line) |> string.to_graphemes() |> list.filter_map(int.parse),
      ..read_lines(stream)
    ]
    _ -> []
  }
}

fn count_trailheads(
  input: Dict(#(Int, Int), Int),
  expected: Int,
  curr: #(Int, Int),
) -> Set(#(Int, Int)) {
  let v = result.unwrap(dict.get(input, curr), 10_000)
  use <- bool.guard(v != expected, set.new())
  use <- bool.guard(v == 9, set.from_list([curr]))

  set.union(
    set.union(
      count_trailheads(input, v + 1, #(curr.0 + 1, curr.1)),
      count_trailheads(input, v + 1, #(curr.0 - 1, curr.1)),
    ),
    set.union(
      count_trailheads(input, v + 1, #(curr.0, curr.1 + 1)),
      count_trailheads(input, v + 1, #(curr.0, curr.1 - 1)),
    ),
  )
}

fn count_paths(
  input: Dict(#(Int, Int), Int),
  expected: Int,
  curr: #(Int, Int),
) -> Int {
  let v = result.unwrap(dict.get(input, curr), 10_000)
  use <- bool.guard(v != expected, 0)
  use <- bool.guard(v == 9, 1)

  count_paths(input, v + 1, #(curr.0 + 1, curr.1))
  + count_paths(input, v + 1, #(curr.0 - 1, curr.1))
  + count_paths(input, v + 1, #(curr.0, curr.1 + 1))
  + count_paths(input, v + 1, #(curr.0, curr.1 - 1))
}

fn part_1(input: Dict(#(Int, Int), Int)) -> Int {
  list.range(0, 57)
  |> list.map(fn(y) {
    list.range(0, 57)
    |> list.filter_map(fn(x) {
      use val <- result.try(dict.get(input, #(x, y)))
      use <- bool.guard(val != 0, Error(Nil))
      Ok(#(x, y))
    })
    |> list.map(fn(v) { count_trailheads(input, 0, v) })
    |> list.map(set.size)
    |> list.fold(0, fn(acc, v) { acc + v })
  })
  |> list.fold(0, fn(acc, v) { acc + v })
}

fn part_2(input: Dict(#(Int, Int), Int)) -> Int {
  list.range(0, 57)
  |> list.map(fn(y) {
    list.range(0, 57)
    |> list.filter_map(fn(x) {
      use val <- result.try(dict.get(input, #(x, y)))
      use <- bool.guard(val != 0, Error(Nil))
      Ok(#(x, y))
    })
    |> list.map(fn(v) { count_paths(input, 0, v) })
    |> list.fold(0, fn(acc, v) { acc + v })
  })
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
  let lines =
    read_lines(stream)
    |> list.index_fold(dict.new(), fn(acc, line, y) {
      list.index_fold(line, dict.new(), fn(acc, v, x) {
        dict.insert(acc, #(x, y), v)
      })
      |> dict.merge(acc)
    })

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
