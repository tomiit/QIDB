class DefinitionsController < ApplicationController
  before_action :set_definition, only: [:show, :edit, :update]
  before_action :set_form_params, only: [:show, :new, :edit]
  before_action :set_log, only: [:show, :edit]

  def show
  end

  def new
  end

  def create
    @definition = Definition.new
    @definition.set_params(params)

    @log = ChangeLog.new
    @log.set_params(params, @definition._id, @definition.log_id)

    # 指標番号や変更者などの必須要素の確認とエラーメッセージ作成
    @error = []
    check_params

    # すでに使われている指標番号を見つける
    @dups = @definition.find_duplicates

    if @error.blank?
      if @dups.blank?
        raise if !(@definition.save && @log.save)
      else
        raise if !(@definition.tmp_save && @log.tmp_save)
      end
    end
  end

  def confirm
    definition = Definition.find(params[:id])
    definition.remove_duplicate
    definition.soft_delete = false
    raise if !definition.save
    log = ChangeLog.where(_id: definition._id).first
    log.soft_delete = false
    raise if !log.save
    redirect_to :def_success
  end

  def success
  end

  def edit
  end

  def update
    @definition = Definition.new
    @definition.set_params(params)

    @log = ChangeLog.new
    @log.set_params(params, @definition._id.to_s)

    # 指標番号や変更者などの必須要素の確認とエラーメッセージ作成
    @error = []
    check_params

    # すでに使われている指標番号を見つける
    @dups = @definition.find_duplicates

    if @dups.blank?
      raise if !@definition.save
    else
      raise if !@definition.tmp_save
    end
  end

  def upload
  end

  def import
    if Definition.read_csv(params[:csv_file])
      render :success
    else
      render :new
    end
  end

  private
    def set_definition
      @definition = Definition.find(params[:id])
    end

    def set_form_params
      @projects = [['QIP', 'qip'], ['日病', 'jha'], ['全自病協', 'jmha'], ['済生会', 'sai'], ['全日本民医連', 'min'],
                   ['日本医師会', 'jma'], ['全日病', 'ajha'], ['国病', 'nho'], ['労災', 'rofuku'], ['慢医協', 'jamcf']]
      @years = ['2008', '2010', '2012', '2014']
      @dataset = ['DPC様式1', 'Fファイル', 'EFファイル', 'Dファイル']
    end

    def set_log
      @logs = ChangeLog.where(soft_delete: false).where(log_id: @definition.log_id).to_a
    end

    def check_params
      if @definition.numbers.blank?
        @error << '指標番号を記入して下さい'
      end
      if @log.editor.blank?
        @error << '変更者を記入して下さい'
      end
      if @log.message.blank?
        @error << '変更メッセージを記入して下さい'
      end
    end

end
