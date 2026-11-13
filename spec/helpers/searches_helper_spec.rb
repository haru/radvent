# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchesHelper do
  describe '#search_excerpt' do
    it 'returns nil for nil, empty and blank bodies', :aggregate_failures do
      expect(helper.search_excerpt(nil, ['a'])).to be_nil
      expect(helper.search_excerpt('', ['a'])).to be_nil
      expect(helper.search_excerpt(" \n\t ", ['a'])).to be_nil
    end

    it 'collapses newlines and runs of whitespace' do
      expect(helper.search_excerpt("one\n\ntwo   three", ['two'])).to eq('one two three')
    end

    it 'centers on the first match with an ellipsis only on the cut sides', :aggregate_failures do
      body = "#{'a' * 200} needle #{'b' * 200}"
      excerpt = helper.search_excerpt(body, ['needle'])
      expect(excerpt).to include('needle')
      expect(excerpt).to start_with('…').and end_with('…')
      expect(excerpt.length).to be_between(100, 140)
    end

    it 'marks only the trailing side when the match is near the start', :aggregate_failures do
      excerpt = helper.search_excerpt("needle #{'b' * 300}", ['needle'])
      expect(excerpt).not_to start_with('…')
      expect(excerpt).to end_with('…')
    end

    it 'marks only the leading side when the match is near the end', :aggregate_failures do
      excerpt = helper.search_excerpt("#{'a' * 300} needle", ['needle'])
      expect(excerpt).to start_with('…')
      expect(excerpt).not_to end_with('…')
    end

    it 'falls back to the head of the body when no keyword appears', :aggregate_failures do
      excerpt = helper.search_excerpt('x' * 300, ['needle'])
      expect(excerpt).to eq("#{'x' * 119}…")
      expect(excerpt.length).to eq(120)
    end

    it 'finds the first match case-insensitively' do
      expect(helper.search_excerpt("#{'a' * 200} NeEdLe #{'b' * 200}", ['needle'])).to include('NeEdLe')
    end

    it 'treats regexp metacharacters in keywords literally', :aggregate_failures do
      expect(helper.search_excerpt("#{'a' * 200} x.*(y #{'b' * 200}", ['.*('])).to include('x.*(y')
      expect(helper.search_excerpt('plain text', ['.*('])).to eq('plain text')
    end

    it 'does not escape the head-of-body fallback, so highlight_keywords escapes it once', :aggregate_failures do
      excerpt = helper.search_excerpt('a < b & c', ['zzz'])
      expect(excerpt).to eq('a < b & c')
      expect(helper.highlight_keywords(excerpt, ['zzz'])).to eq('a &lt; b &amp; c')
    end

    it 'centers on the earliest match among several keywords' do
      body = "#{'a' * 200} second #{'b' * 20} first #{'c' * 200}"
      expect(helper.search_excerpt(body, %w[first second])).to include('second').and include('first')
    end

    it 'raises ArgumentError for empty or blank keywords', :aggregate_failures do
      expect { helper.search_excerpt('text', []) }.to raise_error(ArgumentError)
      expect { helper.search_excerpt('text', ['']) }.to raise_error(ArgumentError)
    end
  end

  describe '#highlight_keywords' do
    it 'wraps only the matches in mark tags, keeping case', :aggregate_failures do
      result = helper.highlight_keywords('Rails and rails', ['rails'])
      expect(result).to eq('<mark>Rails</mark> and <mark>rails</mark>')
      expect(result).to be_html_safe
    end

    it 'highlights every keyword' do
      expect(helper.highlight_keywords('a b c', %w[a c])).to eq('<mark>a</mark> b <mark>c</mark>')
    end

    it 'escapes tags and special characters outside matches', :aggregate_failures do
      result = helper.highlight_keywords('<script>alert(1)</script> & "q"', ['zzz'])
      expect(result).to eq('&lt;script&gt;alert(1)&lt;/script&gt; &amp; &quot;q&quot;')
      expect(result).to be_html_safe
    end

    it 'escapes the inside of a mark' do
      expect(helper.highlight_keywords('x <b> y', ['<b>'])).to eq('x <mark>&lt;b&gt;</mark> y')
    end

    it 'treats regexp metacharacters literally' do
      expect(helper.highlight_keywords('a.b axb', ['.'])).to eq('a<mark>.</mark>b axb')
    end

    it 'marks the longest keyword when keywords overlap' do
      expect(helper.highlight_keywords('ab', %w[a ab])).to eq('<mark>ab</mark>')
    end

    it 'raises ArgumentError for empty or blank keywords', :aggregate_failures do
      expect { helper.highlight_keywords('text', []) }.to raise_error(ArgumentError)
      expect { helper.highlight_keywords('text', [' ']) }.to raise_error(ArgumentError)
    end

    it 'returns the escaped text when nothing matches' do
      expect(helper.highlight_keywords('a & b', ['zzz'])).to eq('a &amp; b')
    end
  end
end
