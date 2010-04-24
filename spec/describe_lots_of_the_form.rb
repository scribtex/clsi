class DescribeLotsOfTheForm
  def initialize(description, parameters)
    @description = description
    @it_should_behave_likes = parameters.delete(:it_should_behave_like)
    @parameters = parameters
    @binding = parameters.delete(:binding)
    
    @parameter_combinations = [{}]
    for parameter, values in parameters
      @parameter_combinations.collect! { |parameter_combination|
        values.collect{|v|
          parameter_combination.merge(parameter => v)  
        }
      }
      @parameter_combinations.flatten!
    end
  end
  
  def describe!
    eval description, @binding
  end
  
  def description
    description = ""
    for parameter_combination in @parameter_combinations
      description += description_from_parameters(parameter_combination)
      description += "\n"
    end
    return description
  end
  
  def description_from_parameters(parameters)
    description = "describe \"#{replace_parameters_in_string(@description, parameters)}\" do\n"
    for it_should_behave_like in @it_should_behave_likes
      description += "  it_should_behave_like \"#{replace_parameters_in_string(it_should_behave_like, parameters)}\"\n"
    end
    description += "end\n"
    return description
  end
  
  def replace_parameters_in_string(string, parameters)
    string = string.dup
    for parameter, value in parameters
      string.gsub!(":#{parameter}", value)
    end
    return string
  end
end

def describe_lots_of_the_form(description, parameters)
  dlotf = DescribeLotsOfTheForm.new(description, parameters)
  dlotf.describe!
end