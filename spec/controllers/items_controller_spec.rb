require 'rails_helper'

RSpec.describe ItemsController, :type => :controller do
  before do
    Event.destroy_all
    AdventCalendarItem.destroy_all
    Item.destroy_all
    @user = create(:user)
    sign_in @user
    @event = create(:event, name: 'test', title: 'test', start_date: '2015-12-01', end_date: '2015-12-30', created_by: @user, updated_by: @user)
    @advent_calendar_item_prev = create(:advent_calendar_item, event: @event, user: @user, date: 1)
    create(:item, advent_calendar_item: @advent_calendar_item_prev)
    @advent_calendar_item = create(:advent_calendar_item, event: @event, user: @user, date: 2)
    create(:item, advent_calendar_item: @advent_calendar_item)
    @advent_calendar_item_next = create(:advent_calendar_item, event: @event, user: @user, date: 3)
    create(:item, advent_calendar_item: @advent_calendar_item_next)

  end
  describe 'GET #show' do
    before :each do
      today = Date.new(2015, 12, 2)
      allow(Time.zone).to receive(:today).and_return(today)
    end

    it "redirects to root if requested item's date doesn't come yet" do
      item = @advent_calendar_item.item
      today = Date.new(2014, 12, 3)
      allow(Time.zone).to receive(:today).and_return(today)
      get :show, params: { id: item }
      expect(response).to redirect_to root_path
    end

    it 'assigns the requested item to @item' do
      item = @advent_calendar_item.item
      get :show, params: { id: item.id }
      expect(assigns(:item)).to eq item
    end

    it 'assigns previous advent_calendar_item to @advent_calendar_item_prev' do
      item = @advent_calendar_item.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_prev)).to eq @advent_calendar_item_prev
    end

    it 'assigns nil to @advent_calendar_item_prev if previous advent_calendar_item is not exist' do
      item = @advent_calendar_item_prev.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_prev)).to be_nil
    end

    it 'assigns next advent_calendar_item to @advent_calendar_item_next' do
      item = @advent_calendar_item.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_next)).to eq @advent_calendar_item_next
    end

    it 'assigns nil to @advent_calendar_item_next if next advent_calendar_item is not exist' do
      item = @advent_calendar_item_next.item
      get :show, params: { id: item }
      expect(assigns(:advent_calendar_item_next)).to be_nil
    end

    it "renders the :show template if item's date is passed" do
      item = @advent_calendar_item_prev.item
      today = Date.new(2016, 11, 2)
      allow(Time.zone).to receive(:today).and_return(today)
      get :show, params: { id: item }
      expect(response).to render_template :show
    end
  end

  describe 'GET #new' do
    it 'assigns the requested date to @date' do
      get :new, params: { date: 1 }
      expect(assigns(:date)).to eq '1'
    end

    it 'assigns a new item to @item' do
      get :new
      expect(assigns(:item)).to be_a_new(Item)
    end

    it 'assigns the requested id to @item.advent_calendar_item_id' do
      get :new, params: { id: 1 }
      expect(assigns(:item).advent_calendar_item_id).to eq 1
    end

    it 'assigns a new attachment to @attachment' do
      get :new
      expect(assigns(:attachment)).to be_a_new(Attachment)
    end

    it 'assigns the requested id to @attachment.advent_calendar_item_id' do
      get :new, params: { id: 1 }
      expect(assigns(:attachment).advent_calendar_item_id).to eq 1
    end

    it 'renders the :new template' do
      get :new
      expect(response).to render_template :new
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested item to @item' do
      advent_calendar_item = create(:advent_calendar_item, date: 2, event: @event, user: @user)
      item = advent_calendar_item.item
      get :edit, params: { use_route: :radvent, id: item }
      expect(assigns(:item)).to eq item
    end

    it 'renders the :edit template' do
      item = @advent_calendar_item.item
      get :edit, params: { use_route: :radvent, id: item }
      expect(response).to render_template :edit
    end

    it 'raises an error when the requested item is not found' do
      expect { get :edit, use_route: :radvent, id: 1 }.to raise_error(Exception)
    end
  end

  describe 'POST #create' do
    it 'saves the new item in the database' do
      advent_calendar_item = create(:advent_calendar_item, date: 8, event: @event, user: @user)
      expect {
        post :create, params: { item: build(:item, advent_calendar_item: advent_calendar_item).attributes }
      }.to change(Item, :count).by(1)
    end

    it 'renders the :new if the new item is not saved' do
      allow_any_instance_of(Item).to receive(:save).and_return(false)
      post :create, params: { item: attributes_for(:item) }
      expect(response).to render_template :new
    end

    it 'redirects to advent_calendar_items#show if the new item is saved' do
      advent_calendar_item = create(:advent_calendar_item, date: 9, event: @event, user: @user)
      post :create, params: { item: build(:item, advent_calendar_item: advent_calendar_item).attributes }
      expect(response).to redirect_to advent_calendar_item_path(id: advent_calendar_item)
    end
  end

  describe 'PATCH #update' do
    before :each do
      @item = @advent_calendar_item.item
    end

    it 'locates the requested @item' do
      patch :update, params: { id: @item, item: attributes_for(:item) }
      expect(assigns(:item)).to eq(@item)
    end

    it "changes @item's attributes" do
      patch :update, params: { id: @item, item: attributes_for(:item,
                                                              title: 'title_updated', body: 'body_updated') }
      @item.reload
      expect(@item.title).to eq('title_updated')
      expect(@item.body).to eq('body_updated')
    end

    it 'renders the :edit if the item is not updated' do
      allow_any_instance_of(Item).to receive(:save).and_return(false)
      patch :update, params: { id: @item, item: attributes_for(:item) }
      expect(response).to render_template :edit
    end

    it 'redirects to advent_calendar_items#show if the item is updated' do
      patch :update, params: { id: @item, item: attributes_for(:item) }
      expect(response).to redirect_to advent_calendar_item_path(@item.advent_calendar_item_id)
    end
  end

  describe 'POST #preview' do
    it 'renders the :preview for a new item' do
      post :preview, params: { item: attributes_for(:item) }
      expect(response).to render_template :preview
    end

    it 'renders the :preview for an existing item' do
      item = @advent_calendar_item.item
      post :preview, params: { id: item, item: attributes_for(:item) }
      expect(response).to render_template :preview
    end
  end
end
