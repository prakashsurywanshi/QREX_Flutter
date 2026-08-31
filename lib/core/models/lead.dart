class Lead {
  final int id;
  final String leadId;
  final String name;
  final String phone;
  final String? email;
  final String source;
  final String status;
  final String? budget;
  final int score;
  final String? preferredLocation;
  final String? requirements;
  final String? nextFollowup;
  final String? lastContact;
  final String? propertyTitle;
  final int? interestedPropertyId;
  final String? agentName;
  final int? agentId;
  final String? campaignName;
  final String? createdBy;
  final String? createdAt;

  const Lead({
    required this.id,
    this.leadId = '',
    required this.name,
    this.phone = '',
    this.email,
    this.source = '',
    this.status = 'New',
    this.budget,
    this.score = 0,
    this.preferredLocation,
    this.requirements,
    this.nextFollowup,
    this.lastContact,
    this.propertyTitle,
    this.interestedPropertyId,
    this.agentName,
    this.agentId,
    this.campaignName,
    this.createdBy,
    this.createdAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'],
      leadId: json['lead_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      source: json['source'] ?? '',
      status: json['status'] ?? 'New',
      budget: json['budget'],
      score: json['score'] ?? 0,
      preferredLocation: json['preferred_location'],
      requirements: json['requirements'],
      nextFollowup: json['next_followup'],
      lastContact: json['last_contact'],
      propertyTitle: json['property_title'],
      interestedPropertyId: json['interested_property_id'],
      agentName: json['agent_name'] ?? json['assigned_agent']?['name'],
      agentId: json['agent_id'] ?? json['assigned_agent_id'],
      campaignName: json['campaign_name'] ?? json['campaign']?['name'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
    );
  }
}

class LeadActivity {
  final int id;
  final String type;
  final String title;
  final String? description;
  final String userName;
  final String createdAt;

  const LeadActivity({
    required this.id,
    this.type = '',
    this.title = '',
    this.description,
    this.userName = 'System',
    this.createdAt = '',
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    return LeadActivity(
      id: json['id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      userName: json['user_name'] ?? 'System',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class LeadOption {
  final int id;
  final String name;

  const LeadOption({required this.id, required this.name});

  factory LeadOption.fromJson(Map<String, dynamic> json) =>
      LeadOption(id: json['id'], name: json['name'] ?? '');
}