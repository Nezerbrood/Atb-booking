
import 'package:atb_booking/data/models/booking.dart';
import 'package:atb_booking/data/services/office_provider.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'admin_bookings_event.dart';

part 'admin_bookings_state.dart';

class AdminBookingsBloc extends Bloc<AdminBookingsEvent, AdminBookingsState> {
  DateTimeRange? _selectedDateTimeRange;
  final int _officeId;
  List<Booking> _loadedBookings = [];
  int _page = 0;

  AdminBookingsBloc(this._officeId) : super(AdminBookingsInitialState(null)) {
    on<AdminBookingsSelectNewRangeEvent>((event, emit) async {
      _selectedDateTimeRange = event.newRange;
      _page = 0;
      emit(AdminBookingsLoadingState(_selectedDateTimeRange, _loadedBookings));
      try {
        _loadedBookings = await OfficeProvider().getBookingsRangeByOfficeId(_officeId,_selectedDateTimeRange!,_page);
        emit(AdminBookingsLoadedState(_selectedDateTimeRange, _loadedBookings));
      } catch (_) {
        emit(AdminBookingsErrorState(_selectedDateTimeRange));//todo add error to pagination
      }
    });
    on<AdminBookingsLoadNextPageEvent>((event, emit) async {
      emit(AdminBookingsLoadingState(_selectedDateTimeRange,_loadedBookings));
      try {
        List<Booking> newPageBookings = await OfficeProvider().getBookingsRangeByOfficeId(_officeId,_selectedDateTimeRange!,_page+1);
        _page++;
        _loadedBookings.addAll(newPageBookings);
        emit(AdminBookingsLoadedState(_selectedDateTimeRange, _loadedBookings));
      } catch (_) {
        emit(AdminBookingsLoadedState(_selectedDateTimeRange, _loadedBookings));
      }
    });
    on<AdminBookingsUpdateEvent>((event, emit) async {
      emit(AdminBookingsLoadingState(_selectedDateTimeRange,_loadedBookings));
      print("update AdminBookingsBloc event");
      try {
        _page = 0;
        _loadedBookings=[];
        List<Booking> newPageBookings = await OfficeProvider().getBookingsRangeByOfficeId(_officeId,_selectedDateTimeRange!,_page);
        _loadedBookings.addAll(newPageBookings);
        emit(AdminBookingsLoadedState(_selectedDateTimeRange, _loadedBookings));
      } catch (_) {
        emit(AdminBookingsErrorState(_selectedDateTimeRange));
      }
    });
  }
}
