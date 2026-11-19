#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerates the project showcase in index.html from index.json and creates
# thumbnails (imgs/thumbs/*.webp) for every screenshot. Requires ImageMagick.
#
# Usage: ruby generate.rb

require 'json'
require 'cgi'
require 'fileutils'
require 'open3'

ROOT       = __dir__
DATA_FILE  = File.join(ROOT, 'index.json')
HTML_FILE  = File.join(ROOT, 'index.html')
THUMBS_DIR = 'imgs/thumbs'
THUMB_SIZE = '480x300'
BEGIN_MARK = '<!-- BEGIN SHOWCASE -->'
END_MARK   = '<!-- END SHOWCASE -->'

def h(text) = CGI.escapeHTML(text.to_s)

def slug(text) = text.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')

def convert_bin
  %w[magick convert].find { |b| system("which #{b} > /dev/null 2>&1") } or
    abort 'ImageMagick (magick/convert) not found'
end

# Creates (or refreshes) a thumbnail and returns its path relative to the site root.
def thumbnail(file)
  src = File.join(ROOT, file)
  abort "Missing screenshot: #{file}" unless File.exist?(src)

  rel  = File.join(THUMBS_DIR, "#{File.basename(file, '.*')}.webp")
  dest = File.join(ROOT, rel)
  return rel if File.exist?(dest) && File.mtime(dest) >= File.mtime(src)

  FileUtils.mkdir_p(File.dirname(dest))
  # Crop to a uniform aspect ratio, anchored at the top of the screenshot.
  _, err, status = Open3.capture3(
    convert_bin, "#{src}[0]", '-thumbnail', "#{THUMB_SIZE}^", '-gravity', 'north',
    '-extent', THUMB_SIZE, '-quality', '80', dest
  )
  abort "Thumbnail failed for #{file}: #{err}" unless status.success?
  puts "thumbnail: #{rel}"
  rel
end

def render_project(project, index)
  id = "#{slug(project['name'])}-#{index}"
  out = []
  out << %(      <article class="project" id="#{h id}">)
  out << %(        <h3>#{h project['name']}</h3>)
  out << %(        <p>#{h project['description']}</p>)

  Array(project['tags']).tap do |tags|
    next if tags.empty?
    out << %(        <ul class="tags">)
    tags.each { |t| out << %(          <li>#{h t}</li>) }
    out << %(        </ul>)
  end

  shots = Array(project['screenshots'])
  unless shots.empty?
    out << %(        <div class="screenshots">)
    shots.each_with_index do |shot, i|
      box = "#{id}-shot-#{i}"
      alt = shot['alt'] || "#{project['name']} screenshot"
      out << %(          <a class="thumb" href="##{h box}"><img src="#{h thumbnail(shot['file'])}" alt="#{h alt}" loading="lazy"></a>)
      out << %(          <a class="lightbox" id="#{h box}" href="##{h id}"><img src="#{h shot['file']}" alt="#{h alt}" loading="lazy"></a>)
    end
    out << %(        </div>)
  end

  links = Array(project['links'])
  unless links.empty?
    out << %(        <p class="links">)
    links.each { |l| out << %(          <a href="#{h l['url']}">#{h l['label']}</a>) }
    out << %(        </p>)
  end

  out << %(      </article>)
  out.join("\n")
end

data = JSON.parse(File.read(DATA_FILE))
projects = Array(data['projects'])
block = ([BEGIN_MARK] + projects.each_with_index.map { |p, i| render_project(p, i) } + ["      #{END_MARK}"]).join("\n")

html = File.read(HTML_FILE)
pattern = /^[ \t]*#{Regexp.escape(BEGIN_MARK)}.*?#{Regexp.escape(END_MARK)}/m
abort "Markers #{BEGIN_MARK} / #{END_MARK} not found in index.html" unless html.match?(pattern)

File.write(HTML_FILE, html.sub(pattern) { "      #{block}" })
puts "index.html updated (#{projects.size} project#{'s' unless projects.size == 1})"
