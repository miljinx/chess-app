class PiecesController < ApplicationController
  def index
    game_id = params[:game_id]
    render json: Game.find(game_id).pieces
  end

  def update
    piece = Piece.find(params[:id])
    piece.update_attributes(piece_params)
    render json: piece
  end

  private

  def piece_params
    params.require(:piece).permit(:row, :col)
  end
end
