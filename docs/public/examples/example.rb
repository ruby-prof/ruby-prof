# A small synthetic workload for demonstrating ruby-prof reports.
# word_freq.rb

def normalize(text)
  text.downcase.gsub(/[^a-z\s]/, "")
end

def tokenize(text)
  text.split(/\s+/)
end

def count_words(words)
  counts = Hash.new(0)
  words.each { |w| counts[w] += 1 }
  counts
end

def top_words(counts, n = 10)
  counts.sort_by { |_, v| -v }.take(n)
end

def run_example
  text = <<~EOS * 200
  Ruby is a dynamic, open source programming language with a focus on
  simplicity and productivity. It has an elegant syntax that is natural
  to read and easy to write.
EOS

  normalized = normalize(text)
  tokens     = tokenize(normalized)
  counts     = count_words(tokens)
  top        = top_words(counts)
end
