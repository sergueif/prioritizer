module Edgesort
  class EdgeStore
    def initialize(file)
      @file = file
      File.write(file, '{"edges": []}') if !File.exist?(file)
      @j = JSON.parse(IO.read(file))
    end

    def edges
      @j['edges']
    end

    def size
      @j['edges'].size
    end

    def each(&block)
      @j['edges'].each(&block)
    end

    def reverse
      @j['edges'].reverse
    end

    def delete(x)
      if @j['edges'].include?(x)
        puts "delete #{x}"
        @j['edges'].delete(x)
        flash!
      end
    end

    def flash!
      File.write(@file, JSON.pretty_generate(@j))
    end

    def <<(edge)
      puts 'adding edge'
      @j['edges'] << edge
      flash!
    end
  end

end
