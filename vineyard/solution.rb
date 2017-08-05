require_relative './bruteforce'
require 'table_print'

pascalito356 = ATITD::Vineyard::BruteForceSolver::TendStrategy.new(
  tend_table: :pascalito356, strategy: :color_skin
).solution
tedra388 = ATITD::Vineyard::BruteForceSolver::TendStrategy.new(
  tend_table: :tedra388, strategy: :grapes
).solution

tp(ATITD::Vineyard::BruteForceSolver::Vineyard::CODES.values.map do |vineyard_state|
  { vineyard: vineyard_state,
    'pascalito356 (tannin)' => pascalito356[vineyard_state],
    'tedra388 (grapes)' => tedra388[vineyard_state]
  }
end.sort_by { |x| x[:vineyard] })
