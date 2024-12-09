import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type Block {
  Empty(size: Int)
  File(size: Int, name: Int)
}

type Input =
  List(Block)

fn read_lines(stream: FileStream, input: Input) -> Input {
  case file_stream.read_line(stream) {
    Ok(line) ->
      string.to_graphemes(line)
      |> list.filter_map(int.parse)
      |> list.index_map(fn(n, i) {
        case n {
          n if i % 2 == 0 -> File(size: n, name: i / 2)
          n -> Empty(n)
        }
      })
    _ -> input
  }
}

fn compact_disk(blocks: List(Block)) -> List(Block) {
  use <- bool.guard(list.is_empty(blocks), [])
  let assert [first, ..rest] = blocks

  case first {
    Empty(es) -> {
      let #(front, last) = list.split(rest, list.length(rest) - 1)
      let assert Ok(last) = list.first(last)
      case last {
        Empty(_) -> compact_disk([first, ..front])
        File(fs, n) if fs > es -> {
          [File(es, n), ..compact_disk(list.append(front, [File(fs - es, n)]))]
        }
        File(fs, n) if fs < es -> [
          File(fs, n),
          ..compact_disk([Empty(es - fs), ..front])
        ]
        File(fs, n) if fs == es -> [File(fs, n), ..compact_disk(front)]
        _ -> panic
      }
    }
    File(..) as file -> [file, ..compact_disk(rest)]
  }
}

fn checksum(blocks: List(Block), i: Int) -> Int {
  case blocks {
    [] -> 0
    [File(0, _), ..rest] -> checksum(rest, i)
    [File(s, n), ..rest] -> checksum([File(s - 1, n), ..rest], i + 1) + n * i
    [Empty(n), ..rest] -> checksum(rest, i + n)
  }
}

fn part_1(input: Input) -> Int {
  compact_disk(input)
  |> checksum(0)
}

fn find_fitting_disk(
  blocks: List(Block),
  size: Int,
) -> Result(#(List(Block), Block), Nil) {
  use <- bool.guard(list.is_empty(blocks), Error(Nil))
  let assert [block, ..rest] = blocks

  case block {
    File(s, _) as file if s <= size -> {
      Ok(#([Empty(s), ..rest], file))
    }
    _ -> {
      case find_fitting_disk(rest, size) {
        Error(Nil) -> Error(Nil)
        Ok(#(rebuilt, found)) -> Ok(#([block, ..rebuilt], found))
      }
    }
  }
}

fn compact_disk2(blocks: List(Block)) -> List(Block) {
  use <- bool.guard(list.is_empty(blocks), [])
  let assert [first, ..rest] = blocks

  case first {
    Empty(es) -> {
      case find_fitting_disk(list.reverse(rest), es) {
        Ok(#(rebuilt, File(fs, _) as file)) if fs == es -> {
          [file, ..compact_disk2(list.reverse(rebuilt))]
        }
        Ok(#(rebuilt, File(fs, _) as file)) if fs < es -> {
          [file, ..compact_disk2([Empty(es - fs), ..list.reverse(rebuilt)])]
        }
        Error(_) -> [Empty(es), ..compact_disk2(rest)]
        _ -> panic
      }
    }
    File(..) as file -> [file, ..compact_disk2(rest)]
  }
}

fn part_2(input: Input) -> Int {
  compact_disk2(input)
  |> checksum(0)
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let lines = read_lines(stream, [])

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
