import argv
import file_streams/file_open_mode
import file_streams/file_stream.{type FileStream}
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import utils

type Antenna {
  Antenna(name: String, x: Int, y: Int)
}

type Input {
  Input(w: Int, h: Int, antennas: List(Antenna))
}

fn read_lines(stream: FileStream, pos: #(Int, Int), input: Input) -> Input {
  case file_stream.read_chars(stream, 1) {
    Ok(".") -> read_lines(stream, #(pos.0 + 1, pos.1), input)
    Ok("\n") ->
      read_lines(
        stream,
        #(0, pos.1 + 1),
        Input(..input, w: pos.0, h: pos.1 + 1),
      )
    Ok(n) ->
      read_lines(
        stream,
        #(pos.0 + 1, pos.1),
        Input(..input, antennas: [Antenna(n, pos.0, pos.1), ..input.antennas]),
      )
    _ -> input
  }
}

fn generate_antinodes(
  input: Input,
  generator: fn(Antenna, Antenna) -> Set(Antenna),
) -> Set(Antenna) {
  input.antennas
  |> list.group(fn(a) { a.name })
  |> dict.map_values(fn(_, a) {
    list.combination_pairs(a)
    |> list.map(fn(pair) { generator(pair.0, pair.1) })
    |> list.fold(set.new(), fn(acc, s) { set.union(acc, s) })
  })
  |> dict.values()
  |> list.fold(set.new(), fn(acc, s) { set.union(acc, s) })
  |> set.filter(fn(a) {
    { 0 <= a.x && a.x < input.w } && { 0 <= a.y && a.y < input.h }
  })
}

fn part_1(input: Input) -> Int {
  generate_antinodes(input, fn(a: Antenna, b: Antenna) {
    set.from_list([
      Antenna("#", a.x - { b.x - a.x }, a.y - { b.y - a.y }),
      Antenna("#", b.x + { b.x - a.x }, b.y + { b.y - a.y }),
    ])
  })
  |> set.size()
}

fn part_2(input: Input) -> Int {
  generate_antinodes(input, fn(a: Antenna, b: Antenna) {
    list.range(-input.w, input.w)
    |> list.map(fn(n) {
      Antenna("#", a.x + { b.x - a.x } * n, a.y + { b.y - a.y } * n)
    })
    |> set.from_list()
  })
  |> set.size()
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open(filename, [file_open_mode.Read])
  use <- utils.defer(fn() { file_stream.close(stream) })

  let lines = read_lines(stream, #(0, 0), Input(0, 0, []))

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
