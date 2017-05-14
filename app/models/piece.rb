# rubocop:disable Metrics/ClassLength
class Piece < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :moves

  scope :are_captured, -> { where(row: -1, col: -1) }
  scope :are_not_captured, -> { where("row > ? AND col > ?", -1, -1) }
  scope :ally_king, ->(is_black) { where(is_black: is_black).where(type: 'King') }

  def self.types
    %w(Pawn Rook Knight Bishop Queen King)
  end

  # Adds an STI type property to the JSON data, rails doesn't do this by default
  def serializable_hash(options = nil)
    super.merge("type" => type)
  end

  def finalize_move!(to_row, to_col)
    return false if self_check?(to_row, to_col)
    move_to!(to_row, to_col)
  end

  def move_to!(to_row, to_col)
    return false unless valid_move?(to_row, to_col)

    move_type = castling?(to_row, to_col)
    captured_id = capture_piece(to_row, to_col)
    move_type = "capture #{captured_id}" if captured_id

    from_row = row
    from_col = col
    update_attributes(row: to_row, col: to_col)
    create_move!(from_row, from_col, move_type)
    true
  end

  def undo_move!
    from_row, from_col = moves.last.from_position
    if (captured_piece_id = get_captive_id(moves.last))
      undo_capture!(captured_piece_id.to_i, row, col)
    end
    moves.last.destroy
    update_attributes(row: from_row, col: from_col)
  end

  def undo_capture!(piece_id, last_row, last_col)
    Piece.find(piece_id).update_attributes(row: last_row, col: last_col)
  end

  def capture_piece(row, col)
    enemy = enemy_at(row, col)
    if enemy
      enemy.captured!
      enemy.id
    else
      false
    end
  end

  def captured!
    update(row: -1, col: -1)
    true
  end

  def captured?
    row < 0 && col < 0
  end

  def castling?(_to_row, _to_col)
    "normal"
  end

  private

  def move_nil?(to_row, to_col)
    row == to_row && col == to_col
  end

  def move_out_of_bounds?(to_row, to_col)
    to_row < 0 || to_row > 7 || to_col < 0 || to_col > 7
  end

  def move_destination_ally?(to_row, to_col)
    ally = game.piece_at(to_row, to_col)
    ally && ally.is_black == is_black ? true : false
  end

  def move_obstructed?(to_row, to_col)
    row_direction = to_row <=> row
    col_direction = to_col <=> col

    current_row = row + row_direction
    current_col = col + col_direction

    until current_row == to_row && current_col == to_col
      return true if game.piece_at(current_row, current_col)
      current_row += row_direction
      current_col += col_direction
    end
    false
  end

  def correct_turn?
    last_move_number = game.moves.last ? game.moves.last.move_number : 0
    (last_move_number.odd? && is_black) || (last_move_number.even? && !is_black)
  end

  def create_move!(from_row, from_col, move_type)
    last_move_number = game.moves.last ? game.moves.last.move_number : 0
    moves.create(
      move_number: last_move_number + 1,
      from_position: [from_row, from_col],
      to_position: [row, col],
      move_type: move_type,
      game_id: game.id
    )
  end

  def enemy_at(check_row, check_col)
    enemy = game.piece_at(check_row, check_col)
    enemy if enemy && enemy.is_black != is_black
  end

  def get_path(to_row, to_col)
    return nil if %w(Rook Bishop Queen).exclude?(type)
    path = []
    current_row = row
    current_col = col
    until current_row == to_row && current_col == to_col
      current_row += to_row <=> current_row
      current_col += to_col <=> current_col
      path << [current_row, current_col]
    end
    path[0..-2]
  end

  def get_captive_id(move)
    last_move_type, captured_piece_id = move.move_type.split
    return captured_piece_id if last_move_type == 'capture'
    nil
  end

  protected

  def valid_move?(to_row, to_col)
    return false unless correct_turn?
    return false if move_nil?(to_row, to_col)
    return false if move_out_of_bounds?(to_row, to_col)
    return false if move_destination_ally?(to_row, to_col)
    return false unless move_legal?(to_row, to_col)
    return false if move_obstructed?(to_row, to_col)
    true
  end

  def self_check?(to_row, to_col)
    return false unless move_to!(to_row, to_col)
    checked = game.pieces.ally_king(is_black).first.in_check? ? true : false
    undo_move!
    checked
  end

  def cant_move?
    (0..7).each do |check_row|
      (0..7).each do |check_col|
        return false if valid_move?(check_row, check_col) && !self_check?(check_row, check_col)
      end
    end
    true
  end
end
