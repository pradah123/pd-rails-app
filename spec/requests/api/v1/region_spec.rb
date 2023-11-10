require 'swagger_helper'

RSpec.describe 'api/v1/region', type: :request do

  path '/api/v1/region' do

    post('create region') do
      consumes 'application/json'
      parameter name: :region, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          logo_image_url: { type: :string },
          header_image_url: { type: :string },
          raw_polygon_json: { type: :string },
          population: { type: :integer },
          status: { type: :string, enum: [:online, :offline] }
        },
        required: [ 'name', 'description', 'logo_url', 'status' ]
      }

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/region/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'

    get('show region') do
      response(200, 'successful') do
        let(:id) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    delete('delete region') do
      response(200, 'successful') do
        let(:id) { '123' }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end  

  path '/api/v1/region/{id}' do

    put('update region') do
      consumes 'application/json'
      parameter name: :region, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          logo_image_url: { type: :string },
          header_image_url: { type: :string },
          raw_polygon_json: { type: :string },
          population: { type: :integer },
          status: { type: :string, enum: [:online, :offline] }
        },
        required: [ 'name', 'description', 'logo_url', 'status' ]
      }

      response(200, 'successful') do
        let(:id) { '123' }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    patch('update region') do
      consumes 'application/json'
      parameter name: :region, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          logo_image_url: { type: :string },
          header_image_url: { type: :string },
          raw_polygon_json: { type: :string },
          population: { type: :integer },
          status: { type: :string, enum: [:online, :offline] }
        },
        required: [ 'name', 'description', 'logo_url', 'status' ]
      }
            
      response(200, 'successful') do
        let(:id) { '123' }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end


  end

end
