# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttachmentsController do
  describe 'POST #create' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:admin_user) { create(:user, admin: true) }
    let(:event) { create(:event) }
    let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: owner) }
    let(:item) { create(:item, advent_calendar_item: advent_calendar_item) }
    let(:image_file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/test.jpg').to_s,
        'image/jpeg'
      )
    end

    before do
      Attachment.destroy_all
      Item.destroy_all
      AdventCalendarItem.destroy_all
      Event.destroy_all
      User.destroy_all
      item
    end

    def upload(item_id: advent_calendar_item.id, image: image_file)
      post :create, params: { attachment: { image: image, advent_calendar_item_id: item_id }.compact }
    end

    context 'when not logged in' do
      it 'redirects to sign in' do
        upload
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when advent_calendar_item_id does not exist' do
      before { sign_in owner }

      it 'returns 404' do
        upload(item_id: 0)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when logged in as a non-editor (not owner, not admin)' do
      before { sign_in other_user }

      it 'returns 403' do
        upload
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when logged in as the article owner' do
      before { sign_in owner }

      it 'saves the new attachment in the database' do
        expect do
          upload
        end.to change(Attachment, :count).by(1)
      end

      it 'returns 200' do
        upload
        expect(response).to have_http_status(:ok)
      end

      it 'returns image_url in json' do
        upload
        expect(response.parsed_body['image_url']).to be_present
      end

      it 'returns the authorized endpoint URL' do
        upload
        attachment = Attachment.last
        expect(response.parsed_body['image_url']).to eq("/attachments/#{attachment.id}/#{attachment.image.identifier}")
      end

      it 'does not write the file under public/uploads' do
        upload
        expect(legacy_upload_dir(Attachment.last)).not_to exist
      end

      it 'includes the relative URL root for sub-path deployments' do
        allow(controller).to(receive(:url_options).and_wrap_original { |m| m.call.merge(script_name: '/radvent') })
        upload
        expect(response.parsed_body['image_url']).to start_with('/radvent/attachments/')
      end

      it 'returns 422 when no image is given' do
        upload(image: nil)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'lets the editor fetch the returned URL right away' do
        upload
        request.env.except!('CONTENT_TYPE', 'RAW_POST_DATA')
        get :show, params: { id: Attachment.last.id, filename: Attachment.last.image.identifier }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when logged in as admin' do
      before { sign_in admin_user }

      it 'saves the new attachment in the database' do
        expect do
          upload
        end.to change(Attachment, :count).by(1)
      end
    end

    context 'when the attachment cannot be saved' do
      before do
        allow_any_instance_of(Attachment).to receive(:save).and_return(false)
        sign_in owner
        upload
      end

      it 'returns success false in json' do
        expect(response.parsed_body['success']).to be(false)
      end

      it 'returns error message in json' do
        expect(response.parsed_body['error']).to be_present
      end
    end
  end

  describe 'GET #show' do
    render_views

    let(:owner) { create(:user) }
    let(:member) { create(:user) }
    let(:outsider) { create(:user) }
    let(:admin_user) { create(:user, admin: true) }
    let(:board) { create(:board, :private_user, owner: owner) }
    let(:event) { create(:event, board: board) }
    let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: owner) }
    let(:attachment) { create(:attachment, advent_calendar_item: advent_calendar_item) }
    let(:filename) { attachment.image.identifier }

    before do
      create(:board_membership, board: board, user: member)
      create(:item, advent_calendar_item: advent_calendar_item)
    end

    def show(id: attachment.id, name: filename)
      get :show, params: { id: id, filename: name }
    end

    context 'when the viewer is a board member' do
      before do
        sign_in member
        show
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.media_type).to eq('image/jpeg') }
      it { expect(response.headers['Content-Disposition']).to start_with('inline') }
      it { expect(response.headers['Cache-Control']).to include('private').and include('no-cache') }
    end

    it 'allows a system admin' do
      sign_in admin_user
      show
      expect(response).to have_http_status(:ok)
    end

    it 'allows the board owner' do
      sign_in owner
      show
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 to a signed-in non-member' do
      sign_in outsider
      show
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 (not a login redirect) to a guest on a private board' do
      show
      expect(response).to have_http_status(:not_found)
    end

    it 'serves a public-board image to a guest' do
      board.update!(visibility: :public)
      show
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for an unknown id' do
      sign_in admin_user
      show(id: 0)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the filename does not match the stored identifier' do
      sign_in admin_user
      show(name: 'other.jpg')
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an orphaned attachment' do
      attachment.update_column(:advent_calendar_item_id, 0) # rubocop:disable Rails/SkipsModelValidations
      sign_in admin_user
      show
      expect(response).to have_http_status(:not_found)
    end

    it 'treats a dot-dot filename as a mismatch, never as a path' do
      sign_in admin_user
      show(name: '..')
      expect(response).to have_http_status(:not_found)
    end

    it 'does not route filenames containing a slash' do
      expect(get: '/attachments/1/../../etc/passwd').not_to be_routable
    end

    # Response captured for each request, so refusals can be compared with each other.
    def responses_for(*requests)
      requests.map do |refused_request|
        refused_request.call
        [response.status, response.body]
      end
    end

    it 'gives a guest the same 404 for denied access, an unknown id and a mismatched filename' do
      responses = responses_for(-> { show }, -> { show(id: 0) }, -> { show(name: 'other.jpg') })
      expect(responses.uniq.size).to eq(1)
    end

    it 'gives a signed-in user the same 404 for denied access, an unknown id and a missing file' do
      sign_in outsider
      make_missing = -> { FileUtils.rm_rf(protected_upload_dir(attachment)) && board.update!(visibility: :public) }
      responses = responses_for(-> { show }, -> { show(id: 0) }, -> { make_missing.call && show })
      expect(responses.uniq.size).to eq(1)
    end

    context 'when an <img> tag sends Accept: image/*' do
      before { request.accept = 'image/avif,image/webp,image/*,*/*;q=0.8' }

      it 'returns the HTML 404 page to a denied guest' do
        show
        expect([response.status, response.media_type]).to eq([404, 'text/html'])
      end

      it 'serves the image to a member' do
        sign_in member
        show
        expect([response.status, response.media_type]).to eq([200, 'image/jpeg'])
      end
    end

    context 'when the article is not published yet' do
      before { event.update!(start_date: 1.year.from_now.beginning_of_month, end_date: 1.year.from_now.end_of_month) }

      it 'returns 404 to a board member' do
        sign_in member
        show
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 to a guest on a public board' do
        board.update!(visibility: :public)
        show
        expect(response).to have_http_status(:not_found)
      end

      it 'serves the image to the article author' do
        sign_in owner
        show
        expect(response).to have_http_status(:ok)
      end
    end

    it 'follows a visibility change on the very next request' do
      sign_in outsider
      show
      board.update!(visibility: :public)
      show
      expect(response).to have_http_status(:ok)
    end

    it 'follows a move to another board on the very next request' do
      sign_in member
      other_event = create(:event, board: create(:board, :private_user, owner: owner))
      advent_calendar_item.update!(event: other_event)
      show
      expect(response).to have_http_status(:not_found)
    end

    context 'with legacy images' do
      let(:attachment) { create(:attachment, :legacy, advent_calendar_item: advent_calendar_item) }

      after { FileUtils.rm_rf(legacy_upload_dir(attachment)) }

      it 'returns 404 to a member, since legacy images use the static URL' do
        sign_in member
        show
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 to a guest' do
        show
        expect(response).to have_http_status(:not_found)
      end

      it 'does not log a missing-file error' do
        allow(Rails.logger).to receive(:error)
        sign_in member
        show
        expect(Rails.logger).not_to have_received(:error).with(/Attachment file/)
      end

      it 'keeps the static file in place' do
        sign_in member
        show
        expect(legacy_upload_dir(attachment).join(filename)).to exist
      end
    end

    context 'when the file is missing everywhere' do
      before do
        FileUtils.rm_rf(protected_upload_dir(attachment))
        allow(Rails.logger).to receive(:error)
        sign_in member
        show
      end

      it { expect(response).to have_http_status(:not_found) }

      it 'logs the attachment id and the expected path as an error' do
        expected = protected_upload_dir(attachment).join(filename)
        expect(Rails.logger).to have_received(:error)
          .with("Attachment file missing or unreadable: attachment_id=#{attachment.id} path=#{expected}")
      end
    end

    context 'when the file exists but cannot be read' do
      before do
        allow_any_instance_of(Pathname).to receive(:readable?).and_return(false)
        allow(Rails.logger).to receive(:error)
        sign_in member
        show
      end

      it { expect(response).to have_http_status(:not_found) }

      it 'logs an error' do
        expect(Rails.logger).to have_received(:error).with(/Attachment file missing or unreadable: attachment_id=/)
      end
    end
  end
end
