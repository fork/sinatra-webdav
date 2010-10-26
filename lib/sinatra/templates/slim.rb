module Sinatra::Templates
  def slim(template, options={}, locals={})
    render :slim, template, options, locals
  end
end
