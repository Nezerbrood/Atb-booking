import 'package:atb_booking/data/models/booking.dart';
import 'package:atb_booking/logic/admin_role/offices/bookings_page/admin_bookings_bloc.dart';
import 'package:atb_booking/logic/user_role/booking/booking_details_bloc/booking_details_bloc.dart';
import 'package:atb_booking/presentation/interface/admin_role/bookings/admin_booking_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AdminBookingsPage extends StatelessWidget {
  AdminBookingsPage({Key? key}) : super(key: key);
  final _textEditingController = TextEditingController();
  final String _defaultText = "defaultText";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Брони в офисе"),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _DateRangePickerWidget(onChanged: (_) {}),
            ),
            _BookingsList()
          ]),
        ));
  }
}

class _DateRangePickerWidget extends StatelessWidget {
  _DateRangePickerWidget({required this.onChanged});

  final void Function(DateTimeRange dateTimeRange) onChanged;
  static const String _defaultText = "Выберите дату";
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingsBloc, AdminBookingsState>(
      builder: (context, state) {
        var selectedDateTimeRange = state.selectedDateTimeRange;
        if (selectedDateTimeRange != null) {
          _textEditingController.text =
              "${DateFormat('dd.MM.yyyy').format(selectedDateTimeRange.start)} - ${DateFormat('dd.MM.yyyy').format(selectedDateTimeRange.end)}";
        }
        return TextField(
          decoration: InputDecoration(
            hintText: "Выберите диапазон дат",
            filled: true,
            fillColor: Theme.of(context).backgroundColor,
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
          ),
          focusNode: _AlwaysDisabledFocusNode(),
          controller: _textEditingController,
          onTap: () async {
            DateTimeRange? newDateTimeRange = await showDateRangePicker(
              context: context,
              builder: (context, child) {
                return child!;
                // return Theme(
                //   data: ThemeData.light().copyWith(
                //     colorScheme: ColorScheme.light(
                //       primary: Theme.of(context).primaryColor,
                //       onPrimary: Colors.white,
                //       surface: Theme.of(context).primaryColor,
                //       onSurface: Colors.black,
                //     ),
                //     dialogBackgroundColor: Colors.white,
                //   ),
                //   child: child!,
                // );
              },
              firstDate: DateTime.now().add(const Duration(days: -365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (newDateTimeRange != null) {
              print("add AdminBookingsSelectNewRangeEvent to bloc");
              context
                  .read<AdminBookingsBloc>()
                  .add(AdminBookingsSelectNewRangeEvent(newDateTimeRange));
              // _textEditingController.text =
              //     "${DateFormat('dd.MM.yyyy').format(newDateTimeRange.start)} - ${DateFormat('dd.MM.yyyy').format(newDateTimeRange.end)}";
            }
          },
        );
      },
    );
  }
}

class _AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class _BookingsList extends StatelessWidget {
  _BookingsList({Key? key}) : super(key: key);
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent ==
          _scrollController.position.pixels) {
        context.read<AdminBookingsBloc>().add(AdminBookingsLoadNextPageEvent());
      }
    });
    return BlocBuilder<AdminBookingsBloc, AdminBookingsState>(
      builder: (context, state) {
        if (state is AdminBookingsLoadedState) {
          if(state.bookings.isEmpty){
            return Center(
                child: Text(
                  "нет броней за этот период",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 22, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ));
          }
          return Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: state.bookings.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      _AdminBookingCard(state.bookings[index]),
                      if (state is AdminBookingsLoadingState &&
                          index == state.bookings.length - 1)
                        Column(
                          children: [
                            const _ShimmerBookingCard(),
                            const _ShimmerBookingCard(),
                          ],
                        ),
                    ],
                  );
                }),
          );
        }
        if (state is AdminBookingsInitialState) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  // child: Text(
                  //   "Выберите интервал дат",
                  //   style: Theme.of(context).textTheme.headlineMedium,
                  //   textAlign: TextAlign.center,),
                ),
              ),
            ),
          );
        } else if(state is AdminBookingsErrorState) {
          return Center(
              child: Text(
                "Не удалось загрузить информацию, проверьте интернет подключение",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 22, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ));
        }else{
          throw Exception("unknown state: $state");
        }
      },
    );
  }
}

class _ShimmerBookingCard extends StatelessWidget {
  const _ShimmerBookingCard({super.key});

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Stack(children: [
        Shimmer.fromColors(
          baseColor: Theme.of(context).backgroundColor,
          highlightColor: Color.fromARGB(211, 217, 217, 217),
          child: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: SizedBox(
                height: 110,
                child: Row(children: [
                  Expanded(
                    flex: 65,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              //_TimeRow(booking),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(flex: 35, child: Container()),
                ]),
              )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Shimmer.fromColors(
              highlightColor: Color.fromARGB(111, 182, 182, 182),
              baseColor: Color.fromARGB(163, 196, 196, 196),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: SizedBox(
                      height: 22,
                      width: 200,
                      child: Row(children: [
                        Expanded(
                          flex: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    //_TimeRow(booking),
                                  ],
                                ),
                                //_WorkspaceRow(booking),
                                //_AddressRow(booking),
                              ],
                            ),
                          ),
                        ),
                        Expanded(flex: 35, child: Container()),
                      ]),
                    )),
              ),
            ),
            Shimmer.fromColors(
              highlightColor: Color.fromARGB(111, 182, 182, 182),
              baseColor: Color.fromARGB(163, 196, 196, 196),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: SizedBox(
                      height: 16,
                      width: 200,
                      child: Row(children: [
                        Expanded(
                          flex: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    //_TimeRow(booking),
                                  ],
                                ),
                                //_WorkspaceRow(booking),
                                //_AddressRow(booking),
                              ],
                            ),
                          ),
                        ),
                        Expanded(flex: 35, child: Container()),
                      ]),
                    )),
              ),
            ),
            Shimmer.fromColors(
              highlightColor: Color.fromARGB(111, 182, 182, 182),
              baseColor: Color.fromARGB(163, 196, 196, 196),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: SizedBox(
                      height: 15,
                      width: 160,
                      child: Row(children: [
                        Expanded(
                          flex: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    //_TimeRow(booking),
                                  ],
                                ),
                                //_WorkspaceRow(booking),
                                //_AddressRow(booking),
                              ],
                            ),
                          ),
                        ),
                        Expanded(flex: 35, child: Container()),
                      ]),
                    )),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final Booking booking;

  const _AdminBookingCard(this.booking);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(providers: [
                          BlocProvider(
                            create: (context) =>
                                BookingDetailsBloc(booking.id, true),
                          ),
                          BlocProvider.value(
                            value: context.read<AdminBookingsBloc>(),
                          ),
                        ], child: const AdminBookingDetailsScreen())));
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 12,
                      child: Center(
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 10),
                          title: Text(
                            booking.workspace.type.type,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'c ' +
                                DateFormat('HH:mm')
                                    .format(booking.reservationInterval.start) +
                                " до " +
                                DateFormat('HH:mm')
                                    .format(booking.reservationInterval.end) +
                                '\n' +
                                DateFormat.yMMMMd("ru_RU")
                                    .format(booking.reservationInterval.start),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          //trailing: trailing ? Icon(Icons.cancel, color: Colors.black) : null,
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 12,
                        child: Center(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(booking.cityName,
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(booking.officeAddress,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ))
                  ],
                ),
              ),
            )));
  }
}
