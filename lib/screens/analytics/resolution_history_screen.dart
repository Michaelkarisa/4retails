import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retails/models/resolution.dart';
import '../../service/data_service.dart';


class ResolutionHistoryScreen extends StatefulWidget {
  const ResolutionHistoryScreen({Key? key}) : super(key: key);
  @override
  State<ResolutionHistoryScreen> createState() => _ResolutionHistoryScreenState();
}

class _ResolutionHistoryScreenState extends State<ResolutionHistoryScreen> with SingleTickerProviderStateMixin {

  @override
  void initState(){
    super.initState();
    getData();
  }
  Future<void> getData() async{
    setState(() {
      isLoading = true;
    });
    resolutions = DataService().getResolutions();
    setState(() {
      isLoading = false;
    });
  }
  List<Resolution> resolutions   = [];
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Resolution History')),
      body: resolutions.isEmpty
          ? const Center(child: Text('No resolutions recorded yet.'))
          : RefreshIndicator(
         onRefresh: ()async{
           await getData();
         },
            child:isLoading?CircularProgressIndicator(): ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: resolutions.length,
                    itemBuilder: (context, index) {
            final r = resolutions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(r.resolution),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMM yyyy – hh:mm a').format(r.date)),
                    const SizedBox(height: 4),
                    const Text('Snapshot: Profit gap > KES 500', style: TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Optional: Show full snapshot
                },
              ),
            );
                    },
                  ),
          ),
    );
  }
}