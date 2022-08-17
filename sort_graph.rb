require 'set'
require 'rgl/adjacency'
require 'rgl/topsort'
require 'rgl/traversal'
require 'rgl/path'
require 'json'

module Edgesort
  class SortGraph
    def initialize(elements, parent_map=Hash.new{ [] })
      @elements = elements
      @parent_map = parent_map
    end

    def load_from_store(store)
      p = Hash.new{ [] }
      g = RGL::DirectedAdjacencyGraph.new
      store.edges.reverse.each do |e| 
        if e['type'] == 'compare' || e['type'].nil?
          child = e['from']
          parent = e['to']

          next unless @elements.include?(child)
          next unless @elements.include?(parent)

          old_parents = p[child]

          p[child] = old_parents | [parent]
          g.add_edge(child, parent)
          print '.'

          if !g.acyclic?
            puts "cycle!"
            g.remove_edge(child, parent)
            p[child] = old_parents
          end
        elsif e['type'] == 'exclude'
          @elements.delete(e['node'])
          puts "Excluding #{e['node']}"
        else
          raise "omg 2"
        end
      end
      puts
      @parent_map = p
    end

    def children(x)
      @elements.select{|e| parents(e, @parent_map).include?(x) }
    end

    def cycles?(pmap)
      @elements.any?{|e| level(e, pmap).nil? }
    end

    def level(e, pmap = @parent_map)
      l = 0
      next_hops = parents(e, pmap)
      next_hop = next_hops.shift
      visited = Set.new
      while next_hop
        return nil if visited.include?(e)

        l += 1
        visited << next_hop
        parents(next_hop, pmap).each do |p|
          next_hops << p unless next_hops.include?(p)
        end
        next_hop = next_hops.shift
      end
      l
    end

    def parents(v, pmap)
      raise 'oops' if !@elements.include?(v)

      pmap[v].select{|p| @elements.include?(p) }
    end

    def top_list
      if one_top
        [one_top] + SortGraph.new(@elements - [one_top], @parent_map).top_list
      else
        []
      end
    end

    def top_level
      @elements.select { |v| parents(v, @parent_map).empty? }
    end

    def one_top
      if top_level.size == 1
        top_level.first
      else
        nil
      end
    end

    def size
      @elements.size
    end

    # def ancestors(e)
    #   @g.bfs_iterator(e).to_a
    # end

    def next_comparison
      tl = without_top_list.top_level
      return nil if tl.size < 2

      tl.sample(2)
    end

    def contenders
      without_top_list.top_level
    end

    def without_top_list
      SortGraph.new(@elements - top_list, @parent_map)
    end

    def exclude(node)
      SortGraph.new(@elements - [node], @parent_map)
    end

    def new_edge(child,parent)
      SortGraph.new(@elements, @parent_map.merge({child => @parent_map[child] + [parent]}))
    end
  end
end
