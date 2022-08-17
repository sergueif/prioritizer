module Edgesort
  class Runner
    def initialize(n: 1)
      @n = n
    end

    def run_file(file, parents_file = nil, recheck_top: false)
      parents_file ||= "#{file}.parents"
      elements = IO.read(file).lines.map(&:strip).reject(&:empty?)
      run_elements(elements, parents_file, recheck_top: recheck_top)
    end

    def run_folder(folder, parents_file = nil, fglob: '*', recheck_top: false)
      parents_file ||= File.join(folder, '.edgesort.parents')
      elements = Dir.glob(File.join(folder, fglob)).map{|p| File.basename(p) }
      run_elements(elements, parents_file, recheck_top: recheck_top)
    end

    def run_elements(elements, parents_file, recheck_top: false)
      store = EdgeStore.new(parents_file)
      s = SortGraph.new(elements)
      s.load_from_store(store)
      if recheck_top
        t = s.top_list
        t.each_cons(2) do |a,b|
          s, exitt = interactive_compare(s, store, a, b)
          return s if exitt
        end
      end
      s = tops_v2(s, @n, store)
      puts 'Tops:'
      puts s.top_list
      s
    end

    def tops_v2(s, n, store)
      until s.top_list.size >= n || s.top_list.size >= s.size
        puts "lets gooooo...#{s.top_list.size},#{n}"
        s = sort(s, n, store)
        if s == s
          puts 'wtf'
          break
        end
      end
      puts "dooooooone #{s.top_list.size >= n} and #{s.top_list.size >= s.size}"
      s
    end

    def tops(s, n, store)
      raise 'see tops v2'
    end

    def sort(s, n, store)
      until s.next_comparison.nil? || s.top_list.size >= n || s.top_list.size >= s.size
        puts "size: #{s.size}, top: #{s.top_list.size}, n: #{n}"
        a, b = s.next_comparison
        #binding.pry
        s, exitt = interactive_compare(s, store, a, b)
        return s if exitt
      end
      s
    end

    def interactive_compare(s, store, a, b)
      puts "---\n(#{s.contenders.size} contenders, l#{s.level(a)} vs l#{s.level(b)}) Please compare:\n#{a}\nvs\n#{
               b
             }\n---"
      input = $stdin.gets
      if input&.strip == '>'
        s = s.new_edge(b,a)
        store << ({ 'type' => 'compare', 'from' => b, 'to' => a, 'created_at' => Time.now })
      elsif input&.strip == '<'
        s = s.new_edge(a,b)
        store << ({ 'type' => 'compare', 'from' => a, 'to' => b, 'created_at' => Time.now })
      elsif input&.strip == 'x1'
        s = s.exclude(a)
        store << ({ 'type' => 'exclude', 'node' => a, 'created_at' => Time.now })
      elsif input&.strip == 'x2'
        s = s.exclude(b)
        store << ({ 'type' => 'exclude', 'node' => b, 'created_at' => Time.now })
      else
        return [s, true]
      end
      return [s, false]
    end

  end

end
