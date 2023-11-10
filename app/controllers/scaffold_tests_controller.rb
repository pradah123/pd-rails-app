class ScaffoldTestsController < ApplicationController
  before_action :set_scaffold_test, only: %i[ show edit update destroy ]

  # GET /scaffold_tests or /scaffold_tests.json
  def index
    @scaffold_tests = ScaffoldTest.all
  end

  # GET /scaffold_tests/1 or /scaffold_tests/1.json
  def show
  end

  # GET /scaffold_tests/new
  def new
    @scaffold_test = ScaffoldTest.new
  end

  # GET /scaffold_tests/1/edit
  def edit
  end

  # POST /scaffold_tests or /scaffold_tests.json
  def create
    @scaffold_test = ScaffoldTest.new(scaffold_test_params)

    respond_to do |format|
      if @scaffold_test.save
        format.html { redirect_to scaffold_test_url(@scaffold_test), notice: "Scaffold test was successfully created." }
        format.json { render :show, status: :created, location: @scaffold_test }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @scaffold_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scaffold_tests/1 or /scaffold_tests/1.json
  def update
    respond_to do |format|
      if @scaffold_test.update(scaffold_test_params)
        format.html { redirect_to scaffold_test_url(@scaffold_test), notice: "Scaffold test was successfully updated." }
        format.json { render :show, status: :ok, location: @scaffold_test }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @scaffold_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scaffold_tests/1 or /scaffold_tests/1.json
  def destroy
    @scaffold_test.destroy

    respond_to do |format|
      format.html { redirect_to scaffold_tests_url, notice: "Scaffold test was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scaffold_test
      @scaffold_test = ScaffoldTest.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def scaffold_test_params
      params.fetch(:scaffold_test, {})
    end
end
