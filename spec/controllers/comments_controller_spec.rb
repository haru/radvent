# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController do
  include_context 'with a board item world'

  let(:item) { world[:item] }

  before do
    Comment.destroy_all
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
  end

  # Signs in as the given role; nil means anonymous.
  def sign_in_as(role)
    sign_in world[role] if role
  end

  def expect_rendered(status, template)
    expect(response).to have_http_status(status)
    expect(response).to render_template(template)
  end

  describe 'POST #create' do
    def post_comment(item_id)
      post :create, params: { comment: { user_name: 'guest', body: 'hello', item_id: item_id } }
    end

    shared_examples 'rejected posts' do |roles|
      roles.each do |role|
        it "responds with 404 and creates nothing for #{role || 'anonymous'}", :aggregate_failures do
          sign_in_as(role)
          expect { post_comment(item.id) }.not_to change(Comment, :count)
          expect_rendered(:not_found, 'errors/notfound')
        end
      end
    end

    context 'when the item is readable' do
      it 'creates the comment for an anonymous user and redirects to the item', :aggregate_failures do
        expect { post_comment(item.id) }.to change(Comment, :count).by(1)
        expect(response).to redirect_to item_path(item)
        expect(Comment.last).to have_attributes(user_name: 'guest', body: 'hello', item_id: item.id)
      end
    end

    context 'when requested as a Turbo Stream' do
      it 'responds with a stream instead of redirecting, so the scroll position is kept', :aggregate_failures do
        post :create, params: { comment: { user_name: 'guest', body: 'hi', item_id: item.id } }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
        expect(response).to render_template('comments/create')
      end
    end

    context 'when the name or the body is blank' do
      render_views

      def post_blank(**)
        post :create, params: { comment: { user_name: ' ', body: 'typed body', item_id: item.id } }, **
      end

      it 'saves nothing and re-renders the article with 422 keeping the typed values', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        expect { post_blank }.not_to change(Comment, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template('items/show')
        page = Capybara.string(response.body)
        expect(page).to have_css('#comment_errors', text: Comment.human_attribute_name(:user_name))
        expect(page).to have_field('comment[body]', with: 'typed body')
        expect(item.reload.comments_count).to eq 0
      end

      it 'keeps the rejected comment out of the list for a user who can delete comments', :aggregate_failures do
        sign_in_as(:owner)
        create(:comment, item: item, user_name: 'saved', body: 'kept')

        expect { post_blank }.not_to change(Comment, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('#comments_list .comment', count: 1)
      end

      it 'renders the breadcrumb of the event like the article page', :aggregate_failures do
        post_blank
        page = Capybara.string(response.body)
        expect(page).to have_css('#top-menu .breadcrumb-event')
        expect(assigns(:board)).to eq item.advent_calendar_item.event.board
      end

      it 'answers a Turbo Stream with 422 and the error messages only', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        expect { post_blank(format: :turbo_stream) }.not_to change(Comment, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
        expect(response.body).to include('target="comment_errors"')
        expect(response.body).to include(Comment.human_attribute_name(:user_name))
        expect(response.body).not_to include('comments_list')
      end
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it_behaves_like 'rejected posts', [nil, :outsider]

      %i[owner member admin].each do |role|
        it "lets #{role} post and redirects to the item", :aggregate_failures do
          sign_in_as(role)
          expect { post_comment(item.id) }.to change(Comment, :count).by(1)
          expect(response).to redirect_to item_path(item)
        end
      end
    end

    context 'when the publish date has not come' do
      let(:today) { Date.new(2015, 12, 4) }

      it_behaves_like 'rejected posts', [nil, :author, :owner, :admin]
    end

    context 'when the item does not exist' do
      it 'responds with 404 and creates nothing', :aggregate_failures do
        expect { post_comment(0) }.not_to change(Comment, :count)
        expect_rendered(:not_found, 'errors/notfound')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:comment) { create(:comment, item: item) }

    def delete_comment(id = comment.id)
      delete :destroy, params: { id: id }
    end

    shared_examples 'rejected deletes' do |roles, status, template|
      roles.each do |role|
        it "responds with #{status} and keeps the comment for #{role || 'anonymous'}", :aggregate_failures do
          sign_in_as(role)
          expect { delete_comment }.not_to change(Comment, :count)
          expect_rendered(status, template)
        end
      end
    end

    shared_examples 'permitted deletes' do |roles|
      roles.each do |role|
        it "deletes the comment and redirects to the item for #{role}", :aggregate_failures do
          sign_in_as(role)
          expect { delete_comment }.to change(Comment, :count).by(-1)
          expect(response).to redirect_to item_path(item.id)
        end
      end
    end

    context 'when the item is readable' do
      it_behaves_like 'rejected deletes', [nil, :outsider, :member, :author], :forbidden, 'errors/forbidden'
      it_behaves_like 'permitted deletes', %i[owner admin]
    end

    context 'when the comment does not exist' do
      it 'responds with 404', :aggregate_failures do
        delete_comment(0)
        expect_rendered(:not_found, 'errors/notfound')
      end
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it_behaves_like 'rejected deletes', [nil, :outsider], :not_found, 'errors/notfound'
      it_behaves_like 'rejected deletes', [:member], :forbidden, 'errors/forbidden'
      it_behaves_like 'permitted deletes', %i[owner admin]
    end

    context 'when the board is protected' do
      let(:visibility) { :protected }

      it_behaves_like 'rejected deletes', [nil, :outsider, :member, :author], :forbidden, 'errors/forbidden'
      it_behaves_like 'permitted deletes', %i[owner admin]
    end

    context 'when the board is the top board' do
      before do
        # Bypass the one-top-board validation: only the board type matters here.
        item.advent_calendar_item.event.board.update_columns(board_type: Board.board_types[:top]) # rubocop:disable Rails/SkipsModelValidations
      end

      it_behaves_like 'rejected deletes', [nil, :outsider], :forbidden, 'errors/forbidden'
    end

    context 'when the board ownership changes between requests' do
      it 'applies the new owner on the next request', :aggregate_failures do
        sign_in_as(:owner)
        item.advent_calendar_item.event.board.update!(owner: world[:outsider])
        expect { delete_comment }.not_to change(Comment, :count)
        expect_rendered(:forbidden, 'errors/forbidden')
      end

      it 'hides a board made private from an anonymous user on the next request', :aggregate_failures do
        item.advent_calendar_item.event.board.update!(visibility: :private)
        expect { delete_comment }.not_to change(Comment, :count)
        expect_rendered(:not_found, 'errors/notfound')
      end
    end

    context 'when the comment is orphaned from its item' do
      before { comment.update_columns(item_id: 0) } # rubocop:disable Rails/SkipsModelValidations

      it 'responds with 404 for a signed-in non-admin', :aggregate_failures do
        sign_in_as(:outsider)
        expect { delete_comment }.not_to change(Comment, :count)
        expect_rendered(:not_found, 'errors/notfound')
      end
    end

    context 'when the client asks for JSON' do
      it 'still renders the 403 page instead of failing', :aggregate_failures do
        sign_in_as(:outsider)
        request.headers['Accept'] = 'application/json'
        delete_comment
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the publish date has not come' do
      let(:today) { Date.new(2015, 12, 4) }

      it_behaves_like 'rejected deletes', [nil, :author], :not_found, 'errors/notfound'
      it_behaves_like 'permitted deletes', %i[owner admin]
    end

    context 'when the user owns a different board' do
      before { sign_in create(:board).owner }

      it 'responds with 403 and keeps the comment', :aggregate_failures do
        expect { delete_comment }.not_to change(Comment, :count)
        expect_rendered(:forbidden, 'errors/forbidden')
      end
    end

    it 'keeps every comment when an unauthorized user deletes them one by one' do
      comments = create_list(:comment, 3, item: item)
      sign_in_as(:outsider)
      expect { comments.each { |c| delete_comment(c.id) } }.not_to change(Comment, :count)
    end
  end
end
