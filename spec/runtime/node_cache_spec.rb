require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module NodeCacheSpec
  include Runtime

  describe NodeCache do
    attr_reader :cache, :input

    before do
      @cache = NodeCache.new
      @input = ('A'..'Z').to_a.join
    end

    describe "with a non-nil parse result stored on a name and interval" do
      attr_reader :node

      before do
        @node = SyntaxNode.new(input, 5..10)
        cache.store(:foo, node)
      end

      describe "#get" do
        it "returns the stored result given the correct name and start index" do
          cache.get(:foo, 5).should == node
        end
      end

      describe "#has_result?" do
        it "returns true when given the correct name and start index" do
          cache.should have_result(:foo, 5)
        end

        it "returns false when given a different name" do
          cache.should_not have_result(:bar, 5)
        end

        it "returns false when given a different start index" do
          cache.should_not have_result(:foo, 2)
        end
      end

      describe "#expire" do
        it "deletes the stored result from the cache when expiring an exactly overlapping interval" do
          cache.should have_result(:foo, 5)
          cache.expire(5..10, 0)
          cache.should_not have_result(:foo, 5)
        end

        it "deletes the stored result from the cache when expiring a partially overlapping interval" do
          cache.should have_result(:foo, 5)
          cache.expire(8..14, 0)
          cache.should_not have_result(:foo, 5)
        end

        it "does not delete the stored result from the cache when expiring a non-overlapping interval" do
          cache.should have_result(:foo, 5)
          cache.expire(3..5, 0)
          cache.should have_result(:foo, 5)
        end
      end
    end

    describe "with results for different rules stored on non-overlapping intervals" do
      attr_reader :the, :green, :dog, :sentence

      before do
        input = "the green dog"
        @the = SyntaxNode.new(input, 0..3)
        @green = SyntaxNode.new(input, 4..9)
        @dog = SyntaxNode.new(input, 10..13)
        @sentence = SyntaxNode.new(input, 0..13)

        cache.store(:the, the)
        cache.store(:color, green)
        cache.store(:dog, dog)
        cache.store(:sentence, sentence)
      end

      it "removes a single result that overlaps an expired range, leaving undisturbed results intact" do
        cache.should have_result(:the, 0)
        cache.should have_result(:color, 4)
        cache.should have_result(:dog, 10)

        cache.expire(green.interval, 0)

        cache.should have_result(:the, 0)
        cache.should_not have_result(:color, 4)
        cache.should have_result(:dog, 10)
      end
    end

    describe "with three results for the same rule stored on three seperate overlapping intervals" do
      attr_reader :a, :b, :c
      
      before do
        @a = SyntaxNode.new(input, 0..5)
        cache.store(:foo, a)

        @b = SyntaxNode.new(input, 3..10)
        cache.store(:foo, b)

        @c = SyntaxNode.new(input, 7..13)
        cache.store(:foo, c)
      end

      it "removes multiple results that overlap an expired range, correctly updating the survivng result with the length_change" do
        cache.get(:foo, 0).should == a
        cache.get(:foo, 3).should == b
        cache.get(:foo, 7).should == c

        cache.expire(3..7, 5)

        cache.should_not have_result(:foo, 0)
        cache.should_not have_result(:foo, 3)
        cache.should_not have_result(:foo, 7)
        cache.get(:foo, 12).should == c
        c.interval.should == (12..18)

        cache.expire(13..15, 0)
        cache.should_not have_result(:foo, 12)
      end
    end
  end
end