class WordsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update, :destroy]

  # 投稿一覧 全ワードのうち公開中のもののみ取得
  def index
    @words = Word.includes(user: :favorites, user: :comments).where(is_published: true).order(created_at: :desc).page(params[:page]).per(10)
  end

  # 新規投稿画面表示
  def new
    @word = Word.new
    @title = "投稿"
  end

  # 新規投稿
  def create
    @word = current_user.words.new(word_params)
    tag_list = params[:tag_name].split(",")
    if params[:public] # 保存ボタンが押された場合公開フラグをtrueで保存
      @word.is_published = true
      if @word.save
        @word.save_tags(tag_list)
        redirect_to word_path(@word)
      else
        render :new
      end
    elsif params[:draft]# 下書きボタンが押された場合公開フラグをfalseで保存
      @word.is_published = false
      if @word.save
        @word.save_tags(tag_list)
        redirect_to word_path(@word)
      else
        render :new
      end
    end
  end

  # 投稿詳細表示
  def show
    @word = Word.find(params[:id])
    @comment = Comment.new
    @tags = Tag.includes(:words)
    # @tag_list = @word.tags
    # binding.pry
  end

  # 投稿編集画面表示
  def edit
    @word = Word.find(params[:id])
    @tag_list = @word.tags.pluck(:tag_name).join(",")
    if @word.is_published == false
      @title = "下書き"
    else
      @title = "編集"
    end
  end

  # 投稿上書き
  def update
    @word = Word.find(params[:id])
    tag_list = params[:tag_name].split(",")
    if params[:public] # 保存ボタンが押された場合公開フラグをtrueで保存
      @word.is_published = true
      if @word.update(word_params)
        @word.save_tags(tag_list)
        redirect_to word_path(@word)
      else
        render :edit
      end
    elsif params[:draft]# 下書きボタンが押された場合公開フラグをfalseで保存
      @word.is_published = false
      if @word.update(word_params)
        @word.save_tags(tag_list)
        redirect_to root_path
      else
        render :edit
      end
    end
  end

  # 投稿削除
  def destroy
    @word = Word.find(params[:id])
    @word.destroy
    redirect_to user_path(current_user)
  end

  private

  # 投稿のストロングパラメータを設定
  def word_params
    params.require(:word).permit(:user_id, :name, :english_name, :description, :is_published)
  end

  #投稿者本人以外のアクセスを禁止
  def correct_user
    @word = Word.find(params[:id])
    unless @word.user_id == current_user.id
      flash[:message] = "アクセス権がありません"
      redirect_to root_path
    end
  end
end