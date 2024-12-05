import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils

type Rule =
  #(Int, Int)

type Input {
  Input(rules: Dict(Int, List(Int)), upgrades: List(List(Int)))
}

fn read_upgrades(
  stream: FileStream,
  upgrades: List(List(Int)),
) -> List(List(Int)) {
  case file_stream.read_line(stream) {
    Ok("") | Error(_) -> upgrades
    Ok(line) -> {
      let upgrade =
        string.split(string.trim(line), ",")
        |> list.map(int.parse)
        |> list.map(fn(v) { result.unwrap(v, 0) })
      read_upgrades(stream, [upgrade, ..upgrades])
    }
  }
}

fn read_rules(stream: FileStream, rules: List(Rule)) -> List(Rule) {
  case file_stream.read_line(stream) {
    Ok("\n") | Ok("") | Error(_) -> rules
    Ok(line) -> {
      let assert Ok(#(low, high)) = string.split_once(string.trim(line), "|")
      let assert Ok(rule) = {
        use low <- result.try(int.parse(low))
        use high <- result.try(int.parse(high))
        Ok(#(low, high))
      }
      read_rules(stream, [rule, ..rules])
    }
  }
}

fn read_lines(stream: FileStream) -> Input {
  let rules =
    read_rules(stream, [])
    |> list.group(fn(v) { v.0 })
    |> dict.map_values(fn(_, v) { list.map(v, fn(a) { a.1 }) })

  let upgrades = read_upgrades(stream, [])
  Input(rules: rules, upgrades: upgrades)
}

fn check_order(update: List(Int), rules: Dict(Int, List(Int))) -> Bool {
  case update {
    [val, ..rest] -> {
      yielder.from_list(rest)
      |> yielder.map(fn(v) {
        result.lazy_unwrap(dict.get(rules, v), fn() { [] })
      })
      |> yielder.all(fn(rule) { !list.contains(rule, val) })
      && check_order(rest, rules)
    }
    [] -> True
  }
}

fn fix_order(
  update: List(Int),
  n: Int,
  rules: Dict(Int, List(Int)),
) -> List(Int) {
  use <- bool.guard(n < 0, update)
  let #(begin, end) = list.split(update, n)

  case check_order(end, rules) {
    True -> fix_order(update, n - 1, rules)
    False -> {
      case end {
        [first, second, ..rest] -> {
          fix_order(
            list.flatten([begin, [second, first, ..rest]]),
            list.length(update) - 1,
            rules,
          )
        }
        _ -> fix_order(update, n - 1, rules)
      }
    }
  }
}

fn part_1(input: Input) -> Int {
  yielder.from_list(input.upgrades)
  |> yielder.filter(fn(v) { check_order(v, input.rules) })
  |> yielder.map(fn(v) {
    result.unwrap(utils.at_index(v, { list.length(v) + 1 } / 2), 0)
  })
  |> yielder.reduce(fn(acc, v) { acc + v })
  |> result.unwrap(0)
}

fn part_2(input: Input) -> Int {
  yielder.from_list(input.upgrades)
  |> yielder.filter(fn(v) { !check_order(v, input.rules) })
  |> yielder.map(fn(v) { fix_order(v, list.length(v) - 1, input.rules) })
  |> yielder.map(fn(v) {
    result.unwrap(utils.at_index(v, { list.length(v) + 1 } / 2), 0)
  })
  |> yielder.reduce(fn(acc, v) { acc + v })
  |> result.unwrap(0)
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)
  // use this line if the order of the input is important!
  // let lines = list.reverse(read_lines(stream, []))
  let lines = read_lines(stream)

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
