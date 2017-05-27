class Pawn < Piece
  def move_legal?(to_row, to_col)
    return true if single_advance?(to_row, to_col)
    return true if double_advance?(to_row, to_col)
    return true if capture_move?(to_row, to_col)
    return true if en_passant?(to_row, to_col)
    false
  end

  private

  def move_destination_ally?(to_row, to_col)
    ally = game.piece_at(to_row, to_col)
    return true if to_col == col && ally
    ally && ally.is_black == is_black ? true : false
  end

  def single_advance?(to_row, to_col)
    to_row == row + forward_one && to_col == col
  end

  def double_advance?(to_row, to_col)
    p '==========================================================='
    p moves.empty?
    to_row == row + forward_two && to_col == col && moves.empty?
  end

  def capture_move?(to_row, to_col)
    to_row == row + forward_one && (to_col - col).abs == 1 && enemy_at(to_row, to_col)
  end

  def en_passant?(to_row, to_col)
    return false unless to_row == row + forward_one && (to_col - col).abs == 1
    enemy = enemy_at(to_row + back_one, to_col)
    enemy && enemy.class == Pawn && enemy.en_passant_vuln?
  end

  def capture_piece(row, col)
    en_passant?(row, col) ? super(row + back_one, col) : super(row, col)
  end

  def forward_one
    is_black ? -1 : 1
  end

  def forward_two
    is_black ? -2 : 2
  end

  def back_one
    is_black ? 1 : -1
  end

  protected

  def en_passant_vuln?
    my_moves = moves
    return false unless my_moves.length == 1
    from_row = my_moves.first.from_position[0]
    row - from_row == forward_two
  end
end
