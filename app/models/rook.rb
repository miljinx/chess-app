class Rook < Piece
  def move_legal?(to_row, to_col)
    col == to_col || row == to_row
  end

  def can_castle_to?(king_col)
    return false if move_obstructed?(row, king_col)
    new_rook_col = col.zero? ? 3 : 5
    update_attributes(row: row, col: new_rook_col)
    true
  end

  def path_to_king
    king = game.pieces.where.not(is_black: is_black).where(type: 'King').first
    return nil unless valid_move?(king.row, king.col)
    get_path(king.row, king.col)
  end
end
