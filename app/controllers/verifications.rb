class Verifications < Application
  include DateParser

  def index
    @centers   = centers(session.user)
    if params[:branch_id]
      @branch    = Branch.get(params[:branch_id])
      @centers   = @centers.reject{|x| x.branch_id!=@branch.id}
    end

    @from_date = params[:from_date] ? parse_date(params[:from_date]).to_time         : Date.min_date
    @to_date   = params[:to_date]   ? parse_date(params[:to_date]).to_time+24*3600-1 : DateTime.now
    case params[:model]
    when "clients"
      @clients  = clients.paginate(:page => params[:page], :per_page => 10)
    when "loans"
      @loans    = loans.paginate(:page => params[:page], :per_page => 20)
    when "payments"
      @payments = payments.paginate(:page => params[:page], :per_page => 100)
    when "portfolios"
      @portfolios = portfolios.paginate(:page => params[:page], :per_page => 100)
    when "journals"
      @journals = journals.paginate(:page => params[:page], :per_page => 100)
    else
      if @centers.length>0
        @clients_count  = clients.count
        @loans_count    = loans.count
        @payments_count = payments.count
        @portfolios_count = portfolios.count
        @journals_count = journals.count
      end
    end
    display "verifications/index"
  end

  def update(id)
    if ["clients", "loans", "payments", "portfolios", "journals"].include?(id) and params[id]
      klass = Kernel.const_get(id.singularize.capitalize)
      verifier_id = session.user.id
      ids = params[id].keys.collect{|x| x.to_i}.join(',')
      repository.adapter.execute("UPDATE #{klass.to_s.downcase.pluralize} SET verified_by_user_id=#{verifier_id.to_i} WHERE id in (#{ids})")
    end
    redirect url(:verifications, :model => id)
  end

  private
  def clients
    hash = {:verified_by_user_id => nil}
    hash[:center_id]  = @centers.map{|x| x.id} if @centers
    hash[:created_at] = @from_date..@to_date
    hash[:fields]     = [:id]
    Client.all(hash)
  end
  
  def loans(type = :objects)
    hash = {:verified_by_user_id => nil}
    hash[:client_id] = Client.all(:center_id => @centers.map{|x| x.id}, :fields => [:id]).map{|x| x.id} if @centers
    hash[:created_at] = @from_date..@to_date
    hash[:fields]     = [:id]
    Loan.all(hash)
  end
  
  def payments(centers = nil, type = :objects)
    hash = {:verified_by_user_id => nil}
    if @centers and not session.user.role==:admin
      hash[:loan_id]   = Loan.all(:client_id => Client.all(:center_id => @centers.map{|x| x.id}, :fields => [:id]).map{|x| x.id}).map{|x| x.id}
    end
    hash[:created_at] = @from_date..@to_date
    hash[:fields]     = [:id]
    Payment.all(hash)
  end

  def portfolios(centers = nil, type = :objects)
    hash = {:verified_by_user_id => nil}
    if session.user.role==:admin
      hash[:created_at] = @from_date..@to_date
      hash[:fields]     = [:id]
      Portfolio.all(hash)
    else
      Portfolio.all(:id => nil)
    end
  end

  def centers(user)
    if user.admin?
      centers = Center.all
    else
      centers = []
      staff = StaffMember.all(:user_id => user.id)
      if staff.length>0
        centers = staff.branches.centers
        centers.uniq!
      end
    end
    centers
  end

  def journals
    hash = {:verified_by_user_id => nil}
    hash[:created_at] = @from_date..@to_date
    hash[:fields]     = [:id]
    Journal.all(hash)
  end

end
