# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsController, '#preview' do
  render_views

  include_context 'with a board item world'

  let(:item) { world[:item] }
  let(:board_name) { item.advent_calendar_item.event.board.name }

  # Builds a slot of the item's author without an article, on the same event as the item.
  #
  # @return [AdventCalendarItem]
  def empty_slot
    @empty_slot ||= create(:advent_calendar_item, event: item.advent_calendar_item.event, user: world[:author],
                                                  user_name: world[:author].name, date: 22)
  end

  # Builds a slot of another user on the same event as the item.
  #
  # @return [AdventCalendarItem]
  def others_slot
    @others_slot ||= create(:advent_calendar_item, event: item.advent_calendar_item.event,
                                                   user: world[:outsider], user_name: 'Other Person', date: 23)
  end

  describe 'preview (existing item)' do
    let(:item_date) { 20 }

    before { item.update!(title: 'Stored Title', body: 'Stored body secret') }

    # Previews the stored item, sending only a title like a partial form would.
    #
    # @param verb [Symbol] the HTTP verb
    # @param attrs [Hash] the item attributes sent
    # @return [void]
    def preview_stored(verb = :post, attrs = { title: 'Typed Title' })
      process :preview, method: verb, params: { id: item.id, item: attrs }
    end

    it 'redirects an anonymous user to the sign-in page' do
      preview_stored
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'responds 404 for a non-existent id' do
      sign_in world[:author]
      process :preview, method: :post, params: { id: Item.maximum(:id) + 1, item: { title: 'x' } }
      expect(response).to have_http_status(:not_found)
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it 'responds 404 to a non-member without leaking the article or the board', :aggregate_failures do
        sign_in world[:outsider]
        preview_stored
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include('Stored Title', 'Stored body secret', board_name)
      end

      it 'responds 403 to a member who did not write the article' do
        sign_in world[:member]
        preview_stored
        expect(response).to have_http_status(:forbidden)
      end
    end

    [Date.new(2015, 12, 10), Date.new(2015, 12, 25)].each do |day|
      context "when today is #{day}" do
        let(:today) { day }

        it 'responds 403 to another user without the stored body', :aggregate_failures do
          sign_in world[:outsider]
          preview_stored
          expect(response).to have_http_status(:forbidden)
          expect(response.body).not_to include('Stored body secret', 'Stored Title')
        end
      end
    end

    it 'responds 403 to another user with GET' do
      sign_in world[:outsider]
      preview_stored(:get)
      expect(response).to have_http_status(:forbidden)
    end

    it 'renders the typed title and the stored body for the author', :aggregate_failures do
      sign_in world[:author]
      preview_stored
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Typed Title', 'Stored body secret')
    end

    it 'renders for the author with GET' do
      sign_in world[:author]
      preview_stored(:get)
      expect(response).to have_http_status(:success)
    end

    it 'ignores a slot of another user sent by the author', :aggregate_failures do
      sign_in world[:author]
      preview_stored(:post, { title: 'Typed Title', advent_calendar_item_id: others_slot.id })
      expect(response).to have_http_status(:success)
      expect(response.body).to include(world[:author].name)
      expect(response.body).not_to include('Other Person')
    end

    it 'renders for an admin' do
      sign_in world[:admin]
      preview_stored
      expect(response).to have_http_status(:success)
    end

    it 'does not save the item' do
      sign_in world[:author]
      expect { preview_stored }.not_to(change { item.reload.attributes })
    end
  end

  describe 'preview_new' do
    # Previews a new article on the given slot id.
    #
    # @param slot_id [Integer, String, nil] the slot id sent
    # @return [void]
    def preview_on(slot_id)
      post :preview_new,
           params: { item: { title: 'Draft Title', body: 'Draft body', advent_calendar_item_id: slot_id } }
    end

    it 'redirects an anonymous user to the sign-in page' do
      preview_on(empty_slot.id)
      expect(response).to redirect_to(new_user_session_path)
    end

    [-> { AdventCalendarItem.maximum(:id).to_i + 1 }, -> { '' }].each_with_index do |slot_id, i|
      it "responds 404 for a missing slot (case #{i})" do
        sign_in world[:author]
        preview_on(slot_id.call)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it 'responds 404 to a non-member without the slot owner', :aggregate_failures do
        sign_in world[:outsider]
        preview_on(empty_slot.id)
        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include(world[:author].name, board_name)
      end
    end

    it 'responds 403 for the slot of another user on a visible board' do
      sign_in world[:outsider]
      preview_on(empty_slot.id)
      expect(response).to have_http_status(:forbidden)
    end

    it 'renders the draft with the slot owner for the owner of the slot', :aggregate_failures do
      sign_in world[:author]
      preview_on(empty_slot.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Draft Title', world[:author].name)
      expect(assigns(:item).advent_calendar_item).to eq empty_slot
    end

    it 'renders for an admin on the slot of another user' do
      sign_in world[:admin]
      preview_on(empty_slot.id)
      expect(response).to have_http_status(:success)
    end

    it 'does not create an item' do
      sign_in world[:author]
      expect { preview_on(empty_slot.id) }.not_to change(Item, :count)
    end
  end
end
