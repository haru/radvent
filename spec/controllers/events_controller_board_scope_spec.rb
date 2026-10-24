# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController do
  render_views

  let(:owner) { create(:user) }
  let(:board_a) { create(:board, :public_user, name: 'Board A Name') }
  let(:board_b) { create(:board, :public_user, name: 'Board B Name') }
  let(:private_board) { create(:board, :private_user, name: 'Hidden Board Name') }
  let(:top_board) { Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' } }

  # Creates an event on the given board.
  #
  # @param board [Board] the board the event belongs to
  # @param name [String] the event name
  # @param creator [User] the creator
  # @return [Event]
  def event_on(board, name, creator: owner)
    create(:event, board: board, name: name, title: "#{board.name} #{name}", start_date: '2015-12-01',
                   end_date: '2015-12-25', created_by: creator, updated_by: creator)
  end

  # Builds the params of a board-scoped request.
  #
  # @param board [Board] the board in the URL
  # @param name [String] the event name in the URL
  # @param extra [Hash] additional params
  # @return [Hash]
  def scoped(board, name, extra = {})
    { board_board_id: board.board_id, name: name }.merge(extra)
  end

  describe 'board-scoped GET #show' do
    it 'shows the event of the requested board (A)' do
      event_on(board_a, 'dup')
      event_on(board_b, 'dup')
      get :show, params: scoped(board_a, 'dup')
      expect(response.body).to include("#{board_a.name} dup")
    end

    it 'shows the event of the requested board (B, reversed creation order)' do
      event_on(board_b, 'dup')
      event_on(board_a, 'dup')
      get :show, params: scoped(board_b, 'dup')
      expect(response.body).to include("#{board_b.name} dup")
    end

    it 'returns 404 for an unknown board' do
      get :show, params: { board_board_id: 'nope', name: 'dup' }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the board has no such event' do
      event_on(board_b, 'dup')
      get :show, params: scoped(board_a, 'dup')
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for a TOP board event addressed through a user board' do
      event_on(top_board, 'topev')
      get :show, params: scoped(board_a, 'topev')
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 and leaks nothing for an invisible private board', :aggregate_failures do
      event_on(private_board, 'secret')
      sign_in create(:user)
      get :show, params: scoped(private_board, 'secret')
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Hidden Board Name')
    end

    it 'returns 404 for a guest on a private board' do
      event_on(private_board, 'secret')
      get :show, params: scoped(private_board, 'secret')
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'board-scoped edit / update / destroy' do
    let(:event) { event_on(board_a, 'dup') }
    let(:update_params) { { event: { title: 'Renamed', name: 'renamed' } } }

    before do
      event
      event_on(board_b, 'dup', creator: create(:user))
    end

    context 'when a guest' do
      it 'returns 403 for edit' do
        get :edit, params: scoped(board_a, 'dup')
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 for update and changes nothing', :aggregate_failures do
        put :update, params: scoped(board_a, 'dup', update_params)
        expect(response).to have_http_status(:forbidden)
        expect(event.reload.title).not_to eq 'Renamed'
      end

      it 'returns 403 for destroy and keeps the event', :aggregate_failures do
        expect { delete :destroy, params: scoped(board_a, 'dup') }.not_to change(Event, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when neither the creator nor an admin' do
      before { sign_in create(:user) }

      it 'returns 403 for edit' do
        get :edit, params: scoped(board_a, 'dup')
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 for update' do
        put :update, params: scoped(board_a, 'dup', update_params)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 for destroy' do
        delete :destroy, params: scoped(board_a, 'dup')
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the board or event does not exist' do
      before { sign_in owner }

      it 'returns 404 for edit on an unknown board' do
        get :edit, params: { board_board_id: 'nope', name: 'dup' }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for update on a board without the event' do
        put :update, params: scoped(board_a, 'missing', update_params)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for destroy through a user board for a TOP event', :aggregate_failures do
        event_on(top_board, 'topev')
        expect { delete :destroy, params: scoped(board_a, 'topev') }.not_to change(Event, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the creator' do
      before { sign_in owner }

      it 'renders edit' do
        get :edit, params: scoped(board_a, 'dup')
        expect(response).to have_http_status(:ok)
      end

      it 'points the edit form and delete button at the board-scoped URL' do
        get :edit, params: scoped(board_a, 'dup')
        expect(response.body).to include(%(action="/boards/#{board_a.board_id}/events/dup"))
      end

      it 'updates and redirects to the board-scoped event page', :aggregate_failures do
        put :update, params: scoped(board_a, 'dup', update_params)
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(board_event_path(board_a.board_id, 'renamed'))
      end

      it 'does not touch the same-named event of another board' do
        put :update, params: scoped(board_a, 'dup', update_params)
        expect(board_b.events.find_by(name: 'dup').title).to eq "#{board_b.name} dup"
      end

      it 'renders edit with 422 on validation errors', :aggregate_failures do
        put :update, params: scoped(board_a, 'dup', event: { title: '' })
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(%(action="/boards/#{board_a.board_id}/events/dup"))
      end

      it 'destroys only this board event and redirects to the board', :aggregate_failures do
        expect { delete :destroy, params: scoped(board_a, 'dup') }.to change(Event, :count).by(-1)
        expect(response).to redirect_to(board_path(board_a.board_id))
        expect(board_b.events.find_by(name: 'dup')).to be_present
      end
    end

    context 'when an admin' do
      before { sign_in create(:user, admin: true) }

      it 'can edit' do
        get :edit, params: scoped(board_a, 'dup')
        expect(response).to have_http_status(:ok)
      end

      it 'can destroy' do
        expect { delete :destroy, params: scoped(board_a, 'dup') }.to change(Event, :count).by(-1)
      end
    end

    context 'when the creator was removed from a private board' do
      let(:event) { event_on(private_board, 'dup') }

      before { sign_in owner }

      it 'returns 404 for edit' do
        get :edit, params: scoped(private_board, 'dup')
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for update' do
        put :update, params: scoped(private_board, 'dup', update_params)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for destroy and keeps the event', :aggregate_failures do
        expect { delete :destroy, params: scoped(private_board, 'dup') }.not_to change(Event, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'name-only URL with a TOP board event' do
    let(:admin) { create(:user, admin: true) }

    [true, false].each do |user_first|
      context "when the user board event was created #{user_first ? 'before' : 'after'} the TOP event" do
        let!(:events) do
          if user_first
            user_ev = event_on(board_a, 'shared')
            [event_on(top_board, 'shared', creator: admin), user_ev]
          else
            top_ev = event_on(top_board, 'shared', creator: admin)
            [top_ev, event_on(board_a, 'shared')]
          end
        end
        let(:top_event) { events.first }
        let(:user_event) { events.last }

        it 'shows the TOP event' do
          get :show, params: { name: 'shared' }
          expect(response.body).to include("TOP shared")
        end

        it 'updates the TOP event only', :aggregate_failures do
          sign_in admin
          put :update, params: { name: 'shared', event: { title: 'Changed' } }
          expect(top_event.reload.title).to eq 'Changed'
          expect(user_event.reload.title).not_to eq 'Changed'
          expect(response).to redirect_to(show_event_path('shared'))
        end

        it 'destroys the TOP event only', :aggregate_failures do
          sign_in admin
          delete :destroy, params: { name: 'shared' }
          expect(Event.exists?(top_event.id)).to be false
          expect(Event.exists?(user_event.id)).to be true
        end

        it 'denies a non-creator non-admin' do
          sign_in owner
          get :edit, params: { name: 'shared' }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'name-only URL without a TOP board event' do
    context 'with a single visible user board event' do
      let!(:event) { event_on(board_a, 'legacy') }

      it 'redirects show with 302 to the board-scoped URL', :aggregate_failures do
        get :show, params: { name: 'legacy' }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/boards/#{board_a.board_id}/events/legacy")
      end

      it 'redirects edit to the board-scoped edit URL, even for non-creators', :aggregate_failures do
        sign_in create(:user)
        get :edit, params: { name: 'legacy' }
        expect(response).to redirect_to("/boards/#{board_a.board_id}/events/legacy/edit")
      end

      it 'returns 404 for update and changes nothing', :aggregate_failures do
        sign_in owner
        put :update, params: { name: 'legacy', event: { title: 'X' } }
        expect(response).to have_http_status(:not_found)
        expect(event.reload.title).not_to eq 'X'
      end

      it 'returns 404 for destroy and keeps the event', :aggregate_failures do
        sign_in owner
        expect { delete :destroy, params: { name: 'legacy' } }.not_to change(Event, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns 404 when nothing matches' do
      get :show, params: { name: 'nothing' }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when two visible user boards match', :aggregate_failures do
      event_on(board_a, 'amb')
      event_on(board_b, 'amb')
      get :show, params: { name: 'amb' }
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Board A Name', 'Board B Name')
    end

    it 'redirects a guest to the public board when the other match is private' do
      event_on(board_a, 'mix')
      event_on(private_board, 'mix')
      get :show, params: { name: 'mix' }
      expect(response).to redirect_to("/boards/#{board_a.board_id}/events/mix")
    end

    it 'returns 404 for a member who sees both matches' do
      [board_a, private_board].each { |board| event_on(board, 'mix') }
      create(:board_membership, board: private_board, user: owner)
      sign_in owner
      get :show, params: { name: 'mix' }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 and leaks nothing when only an invisible private board matches', :aggregate_failures do
      event_on(private_board, 'secret')
      get :show, params: { name: 'secret' }
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Hidden Board Name')
    end
  end
end
