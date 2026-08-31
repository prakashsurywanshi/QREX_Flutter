import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/campaign.dart';
import '../../../core/models/property.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'campaign_detail_sheet.dart';
import 'campaign_form_sheet.dart';
import 'marketing_controller.dart';

class MarketingScreen extends ConsumerStatefulWidget {
  const MarketingScreen({super.key});

  @override
  ConsumerState<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends ConsumerState<MarketingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(marketingControllerProvider.notifier);
      if (ref.read(marketingControllerProvider).campaigns.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketingControllerProvider);
    final controller = ref.read(marketingControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('marketing') == true;
    final canEdit = can?.canEdit('marketing') == true;
    final canDelete = can?.canDelete('marketing') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('New Campaign'),
            )
          : null,
      body: state.loading && state.campaigns.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.campaigns.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  message: state.error!,
                  action: FilledButton(
                      onPressed: controller.load, child: const Text('Retry')),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    children: [
                      _SummaryStrip(state: state),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Campaigns (${state.campaigns.length})',
                        trailing: state.campaigns.isEmpty
                            ? null
                            : TextButton(
                                onPressed: () => _openForm(context),
                                child: const Text('New')),
                        child: state.campaigns.isEmpty
                            ? const EmptyState(
                                icon: Icons.campaign_outlined,
                                message: 'No campaigns yet',
                                hint: 'Create your first campaign.')
                            : Column(
                                children: [
                                  for (final c in state.campaigns)
                                    _CampaignTile(
                                      campaign: c,
                                      onTap: canEdit || canDelete
                                          ? () => _openDetail(context, c,
                                              canEdit, canDelete)
                                          : null,
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      _LeadSourcesCard(sources: state.leadSources),
                      const SizedBox(height: 16),
                      if (state.promotions.isNotEmpty) ...[
                        SectionCard(
                          title: 'Featured Properties',
                          child: Column(
                            children: [
                              for (final p in state.promotions)
                                _PromotionRow(property: p),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (state.landingLeads.isNotEmpty) ...[
                        SectionCard(
                          title: 'Landing Page Leads',
                          child: Column(
                            children: [
                              for (final l in state.landingLeads)
                                _LandingLeadRow(lead: l),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }

  Future<void> _openDetail(
      BuildContext context, Campaign c, bool canEdit, bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CampaignDetailSheet(
        initial: c,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () => ref.read(marketingControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CampaignFormSheet(
        onSaved: () => ref.read(marketingControllerProvider.notifier).load(),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final MarketingState state;
  const _SummaryStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBudget = state.campaigns.fold<double>(
        0, (a, c) => a + c.budget);
    final totalSpent =
        state.campaigns.fold<double>(0, (a, c) => a + c.spent);
    final totalLeads =
        state.campaigns.fold<int>(0, (a, c) => a + c.leads);
    final totalRevenue =
        state.campaigns.fold<double>(0, (a, c) => a + c.revenue);

    Widget cell(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Spent', Formatters.inrLabel(totalSpent), Icons.payments,
            theme.colorScheme.error),
        cell('Budget', Formatters.inrLabel(totalBudget),
            Icons.account_balance_wallet, theme.colorScheme.primary),
        cell('Leads', '$totalLeads', Icons.groups, Colors.green.shade700),
        cell('Revenue', Formatters.inrLabel(totalRevenue),
            Icons.trending_up, theme.colorScheme.tertiary),
      ],
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onTap;
  const _CampaignTile({required this.campaign, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spentRatio = campaign.budget > 0
        ? (campaign.spent / campaign.budget).clamp(0.0, 1.0)
        : 0.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(campaign.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                StatusPill(label: campaign.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${campaign.campaignId} · ${campaign.channel}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: spentRatio,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Spent ${Formatters.inrLabel(campaign.spent)} of ${Formatters.inrLabel(campaign.budget)}',
                  style: theme.textTheme.labelSmall,
                ),
                const Spacer(),
                Icon(Icons.groups, size: 12,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text('${campaign.leads} leads · ${campaign.conversions} conv',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const Divider(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LeadSourcesCard extends StatelessWidget {
  final List<SourceDatum> sources;
  const _LeadSourcesCard({required this.sources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sources.isEmpty) return const SizedBox.shrink();
    final total = sources.fold<int>(0, (a, s) => a + s.value);
    return SectionCard(
      title: 'Lead Sources',
      child: Column(
        children: [
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(s.name,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : (s.value / total).clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: Text('${s.value}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PromotionRow extends StatelessWidget {
  final Property property;
  const _PromotionRow({required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(property.status,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          Text(
            property.priceLabel ?? Formatters.inrLabel(property.price),
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _LandingLeadRow extends StatelessWidget {
  final LandingLead lead;
  const _LandingLeadRow({required this.lead});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          InitialsAvatar(name: lead.name, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.name, style: theme.textTheme.bodyMedium),
                Text(lead.phone,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          Text(lead.status, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}