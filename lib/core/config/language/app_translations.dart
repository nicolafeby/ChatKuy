import 'package:get/get.dart';

class AppTranslations extends Translations {
  static const fallbackLocaleCode = 'id';

  @override
  Map<String, Map<String, String>> get keys => const {
        'id_ID': _id,
        'en_US': _en,
      };
}

class AppTranslationKey {
  const AppTranslationKey._();
  static const appName = 'appName';
  static const somethingWentWrong = 'somethingWentWrong';
  static const tryAgainError = 'tryAgainError';
  static const noData = 'noData';
  static const retry = 'retry';
  static const oopsError = 'oopsError';
  static const appIssueMessage = 'appIssueMessage';
  static const userNotFound = 'userNotFound';
  static const loading = 'loading';
  static const today = 'today';
  static const yesterday = 'yesterday';
  static const weekday1 = 'weekday1';
  static const weekday2 = 'weekday2';
  static const weekday3 = 'weekday3';
  static const weekday4 = 'weekday4';
  static const weekday5 = 'weekday5';
  static const weekday6 = 'weekday6';
  static const weekday7 = 'weekday7';
  static const month1 = 'month1';
  static const month2 = 'month2';
  static const month3 = 'month3';
  static const month4 = 'month4';
  static const month5 = 'month5';
  static const month6 = 'month6';
  static const month7 = 'month7';
  static const month8 = 'month8';
  static const month9 = 'month9';
  static const month10 = 'month10';
  static const month11 = 'month11';
  static const month12 = 'month12';
  static const comingSoonTitle = 'comingSoonTitle';
  static const comingSoonMessage = 'comingSoonMessage';
  static const friends = 'friends';
  static const friend = 'friend';
  static const chats = 'chats';
  static const calls = 'calls';
  static const profile = 'profile';
  static const search = 'search';
  static const closeSearch = 'closeSearch';
  static const clearSearch = 'clearSearch';
  static const searchMessages = 'searchMessages';
  static const searchChats = 'searchChats';
  static const searchCallHistory = 'searchCallHistory';
  static const messageNotFound = 'messageNotFound';
  static const unreadMessages = 'unreadMessages';
  static const chatNotFound = 'chatNotFound';
  static const noChats = 'noChats';
  static const archivedChats = 'archivedChats';
  static const noArchivedChats = 'noArchivedChats';
  static const pleaseLoginAgain = 'pleaseLoginAgain';
  static const securityLoginAgain = 'securityLoginAgain';
  static const message = 'message';
  static const you = 'you';
  static const photo = 'photo';
  static const writeMessage = 'writeMessage';
  static const camera = 'camera';
  static const gallery = 'gallery';
  static const mediaGallery = 'mediaGallery';
  static const media = 'media';
  static const files = 'files';
  static const links = 'links';
  static const noMediaYet = 'noMediaYet';
  static const noFilesYet = 'noFilesYet';
  static const noLinksYet = 'noLinksYet';
  static const openLink = 'openLink';
  static const video = 'video';
  static const document = 'document';
  static const contact = 'contact';
  static const selectContact = 'selectContact';
  static const searchContacts = 'searchContacts';
  static const noContactsFound = 'noContactsFound';
  static const chat = 'chat';
  static const documentSendFailed = 'documentSendFailed';
  static const contactSendFailed = 'contactSendFailed';
  static const voiceMessage = 'voiceMessage';
  static const voiceMessageSendFailed = 'voiceMessageSendFailed';
  static const recording = 'recording';
  static const galleryPermissionDenied = 'galleryPermissionDenied';
  static const cameraPermissionDenied = 'cameraPermissionDenied';
  static const contactPermissionDenied = 'contactPermissionDenied';
  static const microphonePermissionDenied = 'microphonePermissionDenied';
  static const copyTicketId = 'copyTicketId';
  static const errorTicketId = 'errorTicketId';
  static const errorTicketCopied = 'errorTicketCopied';
  static const errorTicketHelp = 'errorTicketHelp';
  static const ok = 'ok';
  static const deleteForMe = 'deleteForMe';
  static const deleteChatTitle = 'deleteChatTitle';
  static const deleteChatsTitle = 'deleteChatsTitle';
  static const deleteChatContent = 'deleteChatContent';
  static const deleteChatFailed = 'deleteChatFailed';
  static const archive = 'archive';
  static const unarchive = 'unarchive';
  static const archiveChatFailed = 'archiveChatFailed';
  static const unarchiveChatFailed = 'unarchiveChatFailed';
  static const deleteMessagesTitle = 'deleteMessagesTitle';
  static const deleteMessagesContent = 'deleteMessagesContent';
  static const cancel = 'cancel';
  static const send = 'send';
  static const delete = 'delete';
  static const reply = 'reply';
  static const videoCall = 'videoCall';
  static const voiceCall = 'voiceCall';
  static const incomingVideoCall = 'incomingVideoCall';
  static const incomingVoiceCall = 'incomingVoiceCall';
  static const invalidCallData = 'invalidCallData';
  static const waitUntilCallConnected = 'waitUntilCallConnected';
  static const videoRequestPending = 'videoRequestPending';
  static const requestingVideoPermission = 'requestingVideoPermission';
  static const videoCallStarted = 'videoCallStarted';
  static const online = 'online';
  static const offline = 'offline';
  static const lastOnlineAt = 'lastOnlineAt';
  static const typing = 'typing';
  static const hiddenOnlineStatus = 'hiddenOnlineStatus';
  static const call = 'call';
  static const reject = 'reject';
  static const accept = 'accept';
  static const end = 'end';
  static const speaker = 'speaker';
  static const close = 'close';
  static const callInfo = 'callInfo';
  static const callHistory = 'callHistory';
  static const audio = 'audio';
  static const noCallHistory = 'noCallHistory';
  static const missedCall = 'missedCall';
  static const ongoingCall = 'ongoingCall';
  static const declined = 'declined';
  static const missed = 'missed';
  static const ongoing = 'ongoing';
  static const ended = 'ended';
  static const seconds = 'seconds';
  static const minutesSeconds = 'minutesSeconds';
  static const fileOpenFailed = 'fileOpenFailed';
  static const incomingRequests = 'incomingRequests';
  static const sentRequests = 'sentRequests';
  static const friendRequests = 'friendRequests';
  static const noIncomingRequests = 'noIncomingRequests';
  static const noSentRequests = 'noSentRequests';
  static const waitingApproval = 'waitingApproval';
  static const addFriend = 'addFriend';
  static const friendAdded = 'friendAdded';
  static const findFriendByUsername = 'findFriendByUsername';
  static const usernameExample = 'usernameExample';
  static const login = 'login';
  static const welcomeBack = 'welcomeBack';
  static const forgotPassword = 'forgotPassword';
  static const resetPassword = 'resetPassword';
  static const forgotPasswordInstruction = 'forgotPasswordInstruction';
  static const usernameOrEmail = 'usernameOrEmail';
  static const enterUsernameOrEmail = 'enterUsernameOrEmail';
  static const sendResetLink = 'sendResetLink';
  static const resetLinkSentTitle = 'resetLinkSentTitle';
  static const resetLinkSentMessage = 'resetLinkSentMessage';
  static const backToLogin = 'backToLogin';
  static const dontHaveAccount = 'dontHaveAccount';
  static const register = 'register';
  static const welcome = 'welcome';
  static const registerSubtitle = 'registerSubtitle';
  static const alreadyHaveAccount = 'alreadyHaveAccount';
  static const verifyNow = 'verifyNow';
  static const verifyEmailToAccessFeatures = 'verifyEmailToAccessFeatures';
  static const verifyEmail = 'verifyEmail';
  static const verifyEmailInstruction = 'verifyEmailInstruction';
  static const newEmailVerifiedMessage = 'newEmailVerifiedMessage';
  static const relogin = 'relogin';
  static const name = 'name';
  static const username = 'username';
  static const email = 'email';
  static const enterName = 'enterName';
  static const enterUsername = 'enterUsername';
  static const enterEmail = 'enterEmail';
  static const emailVerificationRequired = 'emailVerificationRequired';
  static const registrationSuccessTitle = 'registrationSuccessTitle';
  static const resendLink = 'resendLink';
  static const emailChangedTitle = 'emailChangedTitle';
  static const accountSettings = 'accountSettings';
  static const changeEmail = 'changeEmail';
  static const changePassword = 'changePassword';
  static const chooseOption = 'chooseOption';
  static const chooseFromGallery = 'chooseFromGallery';
  static const takePhoto = 'takePhoto';
  static const removePhoto = 'removePhoto';
  static const uploadingImage = 'uploadingImage';
  static const language = 'language';
  static const languageChangedToId = 'languageChangedToId';
  static const languageChangedToEn = 'languageChangedToEn';
  static const indonesian = 'indonesian';
  static const english = 'english';
  static const notifications = 'notifications';
  static const dark = 'dark';
  static const light = 'light';
  static const personalInformation = 'personalInformation';
  static const success = 'success';
  static const profileUpdated = 'profileUpdated';
  static const logout = 'logout';
  static const logoutConfirmationTitle = 'logoutConfirmationTitle';
  static const logoutConfirmationMessage = 'logoutConfirmationMessage';
  static const yearsOld = 'yearsOld';
  static const gender = 'gender';
  static const birthDate = 'birthDate';
  static const phoneNumber = 'phoneNumber';
  static const privacy = 'privacy';
  static const showEmail = 'showEmail';
  static const showEmailSubtitle = 'showEmailSubtitle';
  static const showBirthDate = 'showBirthDate';
  static const showBirthDateSubtitle = 'showBirthDateSubtitle';
  static const showOnlineStatus = 'showOnlineStatus';
  static const showOnlineStatusSubtitle = 'showOnlineStatusSubtitle';
  static const saveChanges = 'saveChanges';
  static const editProfile = 'editProfile';
  static const chooseBirthDate = 'chooseBirthDate';
  static const changePasswordAppbar = 'changePasswordAppbar';
  static const sendingVerificationLink = 'sendingVerificationLink';
  static const currentPassword = 'currentPassword';
  static const password = 'password';
  static const confirmPassword = 'confirmPassword';
  static const enterPassword = 'enterPassword';
  static const enterConfirmPassword = 'enterConfirmPassword';
  static const enterCurrentPassword = 'enterCurrentPassword';
  static const mustLoginAgainAfterPasswordChange =
      'mustLoginAgainAfterPasswordChange';
  static const changeEmailAddress = 'changeEmailAddress';
  static const newEmail = 'newEmail';
  static const enterNewEmail = 'enterNewEmail';
  static const confirm = 'confirm';
  static const failedChangeEmail = 'failedChangeEmail';
  static const currentPasswordWrong = 'currentPasswordWrong';
  static const invalidUser = 'invalidUser';
  static const failedChangePassword = 'failedChangePassword';
  static const emailVerifiedLoginAgain = 'emailVerifiedLoginAgain';
  static const birthDateHidden = 'birthDateHidden';
  static const updateRequired = 'updateRequired';
  static const updateAvailable = 'updateAvailable';
  static const updateRequiredMessage = 'updateRequiredMessage';
  static const updateAvailableMessage = 'updateAvailableMessage';
  static const openAppTester = 'openAppTester';
  static const later = 'later';
  static const failedOpenAppTester = 'failedOpenAppTester';
  static const invalidAppTesterUrl = 'invalidAppTesterUrl';
  static const tryAgainLater = 'tryAgainLater';
  static const yourVersion = 'yourVersion';
  static const minimumAppVersion = 'minimumAppVersion';
  static const recommendedAppVersion = 'recommendedAppVersion';
  static const minimumBuildNumber = 'minimumBuildNumber';
  static const recommendedBuildNumber = 'recommendedBuildNumber';

  static String text(String key, {Map<String, String>? params}) {
    final languageCode = Get.locale?.languageCode;
    final translations = languageCode == 'en' ? _en : _id;
    var value = translations[key] ?? key;

    params?.forEach((paramKey, paramValue) {
      value = value.replaceAll('@$paramKey', paramValue);
    });

    return value;
  }
}

const Map<String, String> _id = {
  AppTranslationKey.appName: 'ChatKuy',
  AppTranslationKey.somethingWentWrong: 'Terjadi kesalahan',
  AppTranslationKey.tryAgainError: 'Terjadi kesalahan, silakan coba lagi',
  AppTranslationKey.noData: 'Data tidak tersedia',
  AppTranslationKey.retry: 'Coba lagi',
  AppTranslationKey.oopsError: 'Ooops!! Terjadi Kesalahan',
  AppTranslationKey.appIssueMessage:
      'Maaf, terjadi kendala pada aplikasi. Silakan coba lagi dalam beberapa saat.',
  AppTranslationKey.userNotFound: 'Akun tidak ditemukan',
  AppTranslationKey.loading: 'Loading',
  AppTranslationKey.today: 'Hari ini',
  AppTranslationKey.yesterday: 'Kemarin',
  AppTranslationKey.weekday1: 'Senin',
  AppTranslationKey.weekday2: 'Selasa',
  AppTranslationKey.weekday3: 'Rabu',
  AppTranslationKey.weekday4: 'Kamis',
  AppTranslationKey.weekday5: 'Jumat',
  AppTranslationKey.weekday6: 'Sabtu',
  AppTranslationKey.weekday7: 'Minggu',
  AppTranslationKey.month1: 'Januari',
  AppTranslationKey.month2: 'Februari',
  AppTranslationKey.month3: 'Maret',
  AppTranslationKey.month4: 'April',
  AppTranslationKey.month5: 'Mei',
  AppTranslationKey.month6: 'Juni',
  AppTranslationKey.month7: 'Juli',
  AppTranslationKey.month8: 'Agustus',
  AppTranslationKey.month9: 'September',
  AppTranslationKey.month10: 'Oktober',
  AppTranslationKey.month11: 'November',
  AppTranslationKey.month12: 'Desember',
  AppTranslationKey.comingSoonTitle: 'Tunggu, yaa...',
  AppTranslationKey.comingSoonMessage: 'Fitur ini akan segera kami luncurkan',
  AppTranslationKey.friends: 'Teman',
  AppTranslationKey.friend: 'Teman',
  AppTranslationKey.chats: 'Percakapan',
  AppTranslationKey.calls: 'Telepon',
  AppTranslationKey.profile: 'Profil',
  AppTranslationKey.search: 'Cari',
  AppTranslationKey.closeSearch: 'Tutup pencarian',
  AppTranslationKey.clearSearch: 'Bersihkan pencarian',
  AppTranslationKey.searchMessages: 'Cari pesan',
  AppTranslationKey.searchChats: 'Cari percakapan',
  AppTranslationKey.searchCallHistory: 'Cari riwayat panggilan',
  AppTranslationKey.messageNotFound: 'Pesan tidak ditemukan',
  AppTranslationKey.unreadMessages: 'Pesan belum dibaca',
  AppTranslationKey.chatNotFound: 'Percakapan tidak ditemukan',
  AppTranslationKey.noChats: 'Belum ada percakapan',
  AppTranslationKey.archivedChats: 'Diarsipkan',
  AppTranslationKey.noArchivedChats: 'Belum ada chat diarsipkan',
  AppTranslationKey.pleaseLoginAgain: 'Silakan masuk kembali',
  AppTranslationKey.securityLoginAgain: 'Silakan login ulang demi keamanan',
  AppTranslationKey.message: 'Pesan',
  AppTranslationKey.you: 'Anda',
  AppTranslationKey.photo: 'Foto',
  AppTranslationKey.writeMessage: 'Tulis pesan...',
  AppTranslationKey.camera: 'Kamera',
  AppTranslationKey.gallery: 'Galeri',
  AppTranslationKey.mediaGallery: 'Media chat',
  AppTranslationKey.media: 'Media',
  AppTranslationKey.files: 'File',
  AppTranslationKey.links: 'Link',
  AppTranslationKey.noMediaYet: 'Belum ada foto atau video',
  AppTranslationKey.noFilesYet: 'Belum ada file',
  AppTranslationKey.noLinksYet: 'Belum ada link',
  AppTranslationKey.openLink: 'Buka link',
  AppTranslationKey.video: 'Video',
  AppTranslationKey.document: 'Dokumen',
  AppTranslationKey.contact: 'Kontak',
  AppTranslationKey.selectContact: 'Pilih Kontak',
  AppTranslationKey.searchContacts: 'Cari kontak...',
  AppTranslationKey.noContactsFound: 'Kontak tidak ditemukan',
  AppTranslationKey.chat: 'Chat',
  AppTranslationKey.documentSendFailed: 'Dokumen gagal dikirim',
  AppTranslationKey.contactSendFailed: 'Kontak gagal dikirim',
  AppTranslationKey.voiceMessage: 'Pesan suara',
  AppTranslationKey.voiceMessageSendFailed: 'Pesan suara gagal dikirim',
  AppTranslationKey.recording: 'Merekam...',
  AppTranslationKey.galleryPermissionDenied:
      'Kami tidak mendapatkan akses galeri untuk action ini',
  AppTranslationKey.cameraPermissionDenied:
      'Kami tidak mendapatkan akses kamera untuk action ini',
  AppTranslationKey.contactPermissionDenied:
      'Kami tidak mendapatkan akses kontak untuk action ini',
  AppTranslationKey.microphonePermissionDenied:
      'Kami tidak mendapatkan akses mikrofon untuk action ini',
  AppTranslationKey.copyTicketId: 'Salin ID tiket',
  AppTranslationKey.errorTicketId: 'ID tiket error',
  AppTranslationKey.errorTicketCopied: 'ID tiket error berhasil disalin',
  AppTranslationKey.errorTicketHelp:
      'Berikan ID tiket ini ke tim teknis agar error bisa dicek pada sistem',
  AppTranslationKey.ok: 'Oke',
  AppTranslationKey.deleteForMe: 'Hapus untuk saya',
  AppTranslationKey.deleteChatTitle: 'Hapus chat dengan @name?',
  AppTranslationKey.deleteChatsTitle: 'Hapus @count chat?',
  AppTranslationKey.deleteChatContent:
      'Chat ini akan dihapus hanya dari daftar dan riwayat Anda.',
  AppTranslationKey.deleteChatFailed: 'Gagal menghapus chat',
  AppTranslationKey.archive: 'Arsipkan',
  AppTranslationKey.unarchive: 'Keluarkan dari arsip',
  AppTranslationKey.archiveChatFailed: 'Gagal mengarsipkan chat',
  AppTranslationKey.unarchiveChatFailed: 'Gagal mengeluarkan chat dari arsip',
  AppTranslationKey.deleteMessagesTitle: 'Hapus @count pesan?',
  AppTranslationKey.deleteMessagesContent:
      'Pesan akan dihapus hanya dari chat Anda.',
  AppTranslationKey.cancel: 'Batal',
  AppTranslationKey.send: 'Kirim',
  AppTranslationKey.delete: 'Hapus',
  AppTranslationKey.reply: 'Balas',
  AppTranslationKey.videoCall: 'Panggilan video',
  AppTranslationKey.voiceCall: 'Telepon suara',
  AppTranslationKey.incomingVideoCall: 'Panggilan video masuk',
  AppTranslationKey.incomingVoiceCall: 'Panggilan suara masuk',
  AppTranslationKey.invalidCallData: 'Data panggilan tidak lengkap',
  AppTranslationKey.waitUntilCallConnected:
      'Tunggu sampai panggilan tersambung',
  AppTranslationKey.videoRequestPending:
      'Permintaan video sedang menunggu persetujuan',
  AppTranslationKey.requestingVideoPermission: 'Meminta izin video...',
  AppTranslationKey.videoCallStarted: 'Panggilan video dimulai',
  AppTranslationKey.online: 'Online',
  AppTranslationKey.offline: 'Offline',
  AppTranslationKey.lastOnlineAt: 'Terakhir online @time',
  AppTranslationKey.typing: 'Sedang mengetik ...',
  AppTranslationKey.hiddenOnlineStatus: 'Status online disembunyikan',
  AppTranslationKey.call: 'Panggilan',
  AppTranslationKey.reject: 'Tolak',
  AppTranslationKey.accept: 'Terima',
  AppTranslationKey.end: 'Akhiri',
  AppTranslationKey.speaker: 'Speaker',
  AppTranslationKey.close: 'Tutup',
  AppTranslationKey.callInfo: 'Info panggilan',
  AppTranslationKey.callHistory: 'Telepon',
  AppTranslationKey.audio: 'Audio',
  AppTranslationKey.noCallHistory: 'Belum ada riwayat panggilan',
  AppTranslationKey.missedCall: 'Panggilan tak terjawab',
  AppTranslationKey.ongoingCall: 'Panggilan berlangsung',
  AppTranslationKey.declined: 'Ditolak',
  AppTranslationKey.missed: 'Tak terjawab',
  AppTranslationKey.ongoing: 'Berlangsung',
  AppTranslationKey.ended: 'Berakhir',
  AppTranslationKey.seconds: '@count detik',
  AppTranslationKey.minutesSeconds: '@minutes menit @seconds detik',
  AppTranslationKey.fileOpenFailed: 'File tidak bisa dibuka',
  AppTranslationKey.incomingRequests: 'Masuk',
  AppTranslationKey.sentRequests: 'Terkirim',
  AppTranslationKey.friendRequests: 'Permintaan Pertemanan',
  AppTranslationKey.noIncomingRequests: 'Tidak ada permintaan masuk',
  AppTranslationKey.noSentRequests: 'Tidak ada permintaan terkirim',
  AppTranslationKey.waitingApproval: 'Menunggu persetujuan',
  AppTranslationKey.addFriend: 'Tambah Teman',
  AppTranslationKey.friendAdded: 'Teman berhasil ditambahkan',
  AppTranslationKey.findFriendByUsername: 'Cari teman dengan username',
  AppTranslationKey.usernameExample: 'contoh: nicola123',
  AppTranslationKey.login: 'Masuk',
  AppTranslationKey.welcomeBack: 'Welcome Back',
  AppTranslationKey.forgotPassword: 'Lupa Password?',
  AppTranslationKey.resetPassword: 'Reset Password',
  AppTranslationKey.forgotPasswordInstruction:
      'Masukkan username atau email akun kamu. Jika akun ditemukan, kami akan mengirim link reset password ke email terdaftar.',
  AppTranslationKey.usernameOrEmail: 'Username atau Email',
  AppTranslationKey.enterUsernameOrEmail: 'Masukan username atau email',
  AppTranslationKey.sendResetLink: 'Kirim Link Reset',
  AppTranslationKey.resetLinkSentTitle: 'Cek Email Kamu',
  AppTranslationKey.resetLinkSentMessage:
      'Jika akun ditemukan, link reset password sudah kami kirim ke email terdaftar.',
  AppTranslationKey.backToLogin: 'Kembali ke Login',
  AppTranslationKey.dontHaveAccount: 'Tidak punya akun? ',
  AppTranslationKey.register: 'Daftar',
  AppTranslationKey.welcome: 'Selamat Datang',
  AppTranslationKey.registerSubtitle:
      'Yuk, buat akun sekarang agar kita tetap nyambung!!',
  AppTranslationKey.alreadyHaveAccount: 'Sudah punya akun? ',
  AppTranslationKey.verifyNow: 'Verifikasi Sekarang',
  AppTranslationKey.verifyEmailToAccessFeatures:
      'Yuk, verifikasi email kamu agar bisa mengakses semua fitur kami',
  AppTranslationKey.verifyEmail: 'Verifikasi Email',
  AppTranslationKey.verifyEmailInstruction:
      'Buka email @email dan klik link verifikasi yang kami kirim',
  AppTranslationKey.newEmailVerifiedMessage:
      'Email baru kamu sudah berhasil diverifikasi. Untuk keamanan akun, silakan login ulang menggunakan username dan password kamu.',
  AppTranslationKey.relogin: 'Login Ulang',
  AppTranslationKey.name: 'Nama',
  AppTranslationKey.username: 'Username',
  AppTranslationKey.email: 'Email',
  AppTranslationKey.enterName: 'Masukan Nama',
  AppTranslationKey.enterUsername: 'Masukan Username',
  AppTranslationKey.enterEmail: 'Masukan Email',
  AppTranslationKey.emailVerificationRequired:
      'Mohon verifikasi email kamu agar bisa mengakses seluruh fitur',
  AppTranslationKey.registrationSuccessTitle: 'Horee!! Registrasi Berhasil',
  AppTranslationKey.resendLink: 'Kirim Ulang Link',
  AppTranslationKey.emailChangedTitle: 'Email Berhasil Diubah',
  AppTranslationKey.accountSettings: 'Pengaturan Akun',
  AppTranslationKey.changeEmail: 'Ubah Email',
  AppTranslationKey.changePassword: 'Ubah Password',
  AppTranslationKey.chooseOption: 'Pilih Opsi',
  AppTranslationKey.chooseFromGallery: 'Pilih dari galeri',
  AppTranslationKey.takePhoto: 'Ambil foto',
  AppTranslationKey.removePhoto: 'Hapus foto',
  AppTranslationKey.uploadingImage: 'Mengunggah gambar...',
  AppTranslationKey.language: 'Bahasa',
  AppTranslationKey.languageChangedToId: 'Bahasa diubah ke Indonesia.',
  AppTranslationKey.languageChangedToEn: 'Language changed to English.',
  AppTranslationKey.indonesian: 'Indonesia',
  AppTranslationKey.english: 'Inggris',
  AppTranslationKey.notifications: 'Notifikasi',
  AppTranslationKey.dark: 'Gelap',
  AppTranslationKey.light: 'Terang',
  AppTranslationKey.personalInformation: 'Informasi Personal',
  AppTranslationKey.success: 'Sukses',
  AppTranslationKey.profileUpdated: 'Berhasil Mengubah Profile',
  AppTranslationKey.logout: 'Keluar',
  AppTranslationKey.logoutConfirmationTitle: 'Keluar dari akun?',
  AppTranslationKey.logoutConfirmationMessage:
      'Kamu perlu login kembali untuk menggunakan ChatKuy.',
  AppTranslationKey.yearsOld: '@age tahun',
  AppTranslationKey.gender: 'Jenis kelamin',
  AppTranslationKey.birthDate: 'Tanggal lahir',
  AppTranslationKey.phoneNumber: 'Nomor HP',
  AppTranslationKey.privacy: 'Privasi',
  AppTranslationKey.showEmail: 'Tampilkan email',
  AppTranslationKey.showEmailSubtitle:
      'Izinkan teman melihat alamat email kamu',
  AppTranslationKey.showBirthDate: 'Tampilkan tanggal lahir',
  AppTranslationKey.showBirthDateSubtitle:
      'Izinkan teman melihat tanggal lahir kamu',
  AppTranslationKey.showOnlineStatus: 'Tampilkan status online',
  AppTranslationKey.showOnlineStatusSubtitle:
      'Izinkan teman melihat status online kamu. Jika dimatikan, kamu juga tidak bisa melihat status online teman.',
  AppTranslationKey.saveChanges: 'Simpan Perubahan',
  AppTranslationKey.editProfile: 'Ubah Profile',
  AppTranslationKey.chooseBirthDate: 'Pilih tanggal lahir',
  AppTranslationKey.changePasswordAppbar: 'Ganti Password',
  AppTranslationKey.sendingVerificationLink: 'Mengirim link verifikasi...',
  AppTranslationKey.currentPassword: 'Password Sekarang',
  AppTranslationKey.password: 'Password',
  AppTranslationKey.confirmPassword: 'Konfirmasi Password',
  AppTranslationKey.enterPassword: 'Masukan password',
  AppTranslationKey.enterConfirmPassword: 'Masukan konfirmasi password',
  AppTranslationKey.enterCurrentPassword: 'Masukan password sekarang',
  AppTranslationKey.mustLoginAgainAfterPasswordChange:
      'Kamu harus login ulang setelah mengganti password',
  AppTranslationKey.changeEmailAddress: 'Ubah Alamat Email',
  AppTranslationKey.newEmail: 'Email Baru',
  AppTranslationKey.enterNewEmail: 'Masukan email baru kamu',
  AppTranslationKey.confirm: 'Konfirmasi',
  AppTranslationKey.failedChangeEmail: 'Gagal mengganti email',
  AppTranslationKey.currentPasswordWrong: 'Password lama salah',
  AppTranslationKey.invalidUser: 'User tidak valid',
  AppTranslationKey.failedChangePassword: 'Gagal mengganti password',
  AppTranslationKey.emailVerifiedLoginAgain:
      'Email berhasil diverifikasi. Silakan login ulang.',
  AppTranslationKey.birthDateHidden: 'Disembunyikan',
  AppTranslationKey.updateRequired: 'Update Diperlukan',
  AppTranslationKey.updateAvailable: 'Update Tersedia',
  AppTranslationKey.updateRequiredMessage:
      'Versi ChatKuy yang kamu pakai sudah berada di bawah minimum yang didukung.',
  AppTranslationKey.updateAvailableMessage:
      'Ada versi ChatKuy yang lebih baru. Kamu bisa update sekarang atau lanjut dulu.',
  AppTranslationKey.openAppTester: 'Buka App Tester',
  AppTranslationKey.later: 'Nanti saja',
  AppTranslationKey.failedOpenAppTester: 'Gagal membuka App Tester',
  AppTranslationKey.invalidAppTesterUrl: 'URL App Tester tidak valid',
  AppTranslationKey.tryAgainLater: 'Silakan coba lagi beberapa saat lagi',
  AppTranslationKey.yourVersion: 'Versi kamu',
  AppTranslationKey.minimumAppVersion: 'Minimal app version',
  AppTranslationKey.recommendedAppVersion: 'Rekomendasi app version',
  AppTranslationKey.minimumBuildNumber: 'Minimal build number',
  AppTranslationKey.recommendedBuildNumber: 'Rekomendasi build number',
};

const Map<String, String> _en = {
  AppTranslationKey.appName: 'ChatKuy',
  AppTranslationKey.somethingWentWrong: 'Something went wrong',
  AppTranslationKey.tryAgainError: 'Something went wrong, please try again',
  AppTranslationKey.noData: 'No data available',
  AppTranslationKey.retry: 'Try again',
  AppTranslationKey.oopsError: 'Ooops!! Something Went Wrong',
  AppTranslationKey.appIssueMessage:
      'Sorry, the app ran into a problem. Please try again in a moment.',
  AppTranslationKey.userNotFound: 'Account not found',
  AppTranslationKey.loading: 'Loading',
  AppTranslationKey.today: 'Today',
  AppTranslationKey.yesterday: 'Yesterday',
  AppTranslationKey.weekday1: 'Monday',
  AppTranslationKey.weekday2: 'Tuesday',
  AppTranslationKey.weekday3: 'Wednesday',
  AppTranslationKey.weekday4: 'Thursday',
  AppTranslationKey.weekday5: 'Friday',
  AppTranslationKey.weekday6: 'Saturday',
  AppTranslationKey.weekday7: 'Sunday',
  AppTranslationKey.month1: 'January',
  AppTranslationKey.month2: 'February',
  AppTranslationKey.month3: 'March',
  AppTranslationKey.month4: 'April',
  AppTranslationKey.month5: 'May',
  AppTranslationKey.month6: 'June',
  AppTranslationKey.month7: 'July',
  AppTranslationKey.month8: 'August',
  AppTranslationKey.month9: 'September',
  AppTranslationKey.month10: 'October',
  AppTranslationKey.month11: 'November',
  AppTranslationKey.month12: 'December',
  AppTranslationKey.comingSoonTitle: 'Hang tight...',
  AppTranslationKey.comingSoonMessage: 'This feature is coming soon',
  AppTranslationKey.friends: 'Friends',
  AppTranslationKey.friend: 'Friend',
  AppTranslationKey.chats: 'Chats',
  AppTranslationKey.calls: 'Calls',
  AppTranslationKey.profile: 'Profile',
  AppTranslationKey.search: 'Search',
  AppTranslationKey.closeSearch: 'Close search',
  AppTranslationKey.clearSearch: 'Clear search',
  AppTranslationKey.searchMessages: 'Search messages',
  AppTranslationKey.searchChats: 'Search chats',
  AppTranslationKey.searchCallHistory: 'Search call history',
  AppTranslationKey.messageNotFound: 'Message not found',
  AppTranslationKey.unreadMessages: 'Unread messages',
  AppTranslationKey.chatNotFound: 'Chat not found',
  AppTranslationKey.noChats: 'No chats yet',
  AppTranslationKey.archivedChats: 'Archived',
  AppTranslationKey.noArchivedChats: 'No archived chats yet',
  AppTranslationKey.pleaseLoginAgain: 'Please sign in again',
  AppTranslationKey.securityLoginAgain: 'Please sign in again for security',
  AppTranslationKey.message: 'Message',
  AppTranslationKey.you: 'You',
  AppTranslationKey.photo: 'Photo',
  AppTranslationKey.writeMessage: 'Write a message...',
  AppTranslationKey.camera: 'Camera',
  AppTranslationKey.gallery: 'Gallery',
  AppTranslationKey.mediaGallery: 'Chat media',
  AppTranslationKey.media: 'Media',
  AppTranslationKey.files: 'Files',
  AppTranslationKey.links: 'Links',
  AppTranslationKey.noMediaYet: 'No photos or videos yet',
  AppTranslationKey.noFilesYet: 'No files yet',
  AppTranslationKey.noLinksYet: 'No links yet',
  AppTranslationKey.openLink: 'Open link',
  AppTranslationKey.video: 'Video',
  AppTranslationKey.document: 'Document',
  AppTranslationKey.contact: 'Contact',
  AppTranslationKey.selectContact: 'Select a Contact',
  AppTranslationKey.searchContacts: 'Search contacts...',
  AppTranslationKey.noContactsFound: 'No contacts found',
  AppTranslationKey.chat: 'Chat',
  AppTranslationKey.documentSendFailed: 'Failed to send document',
  AppTranslationKey.contactSendFailed: 'Failed to send contact',
  AppTranslationKey.voiceMessage: 'Voice message',
  AppTranslationKey.voiceMessageSendFailed: 'Failed to send voice message',
  AppTranslationKey.recording: 'Recording...',
  AppTranslationKey.galleryPermissionDenied:
      'We could not access your gallery for this action',
  AppTranslationKey.cameraPermissionDenied:
      'We could not access your camera for this action',
  AppTranslationKey.contactPermissionDenied:
      'We could not access your contacts for this action',
  AppTranslationKey.microphonePermissionDenied:
      'We could not access your microphone for this action',
  AppTranslationKey.copyTicketId: 'Copy ticket ID',
  AppTranslationKey.errorTicketId: 'Error ticket ID',
  AppTranslationKey.errorTicketCopied: 'Error ticket ID copied',
  AppTranslationKey.errorTicketHelp:
      'Share this ticket ID with the technical team so the error can be checked in the system',
  AppTranslationKey.ok: 'OK',
  AppTranslationKey.deleteForMe: 'Delete for me',
  AppTranslationKey.deleteChatTitle: 'Delete chat with @name?',
  AppTranslationKey.deleteChatsTitle: 'Delete @count chats?',
  AppTranslationKey.deleteChatContent:
      'This chat will only be deleted from your list and history.',
  AppTranslationKey.deleteChatFailed: 'Failed to delete chat',
  AppTranslationKey.archive: 'Archive',
  AppTranslationKey.unarchive: 'Unarchive',
  AppTranslationKey.archiveChatFailed: 'Failed to archive chat',
  AppTranslationKey.unarchiveChatFailed: 'Failed to unarchive chat',
  AppTranslationKey.deleteMessagesTitle: 'Delete @count messages?',
  AppTranslationKey.deleteMessagesContent:
      'Messages will only be deleted from your chat.',
  AppTranslationKey.cancel: 'Cancel',
  AppTranslationKey.send: 'Send',
  AppTranslationKey.delete: 'Delete',
  AppTranslationKey.reply: 'Reply',
  AppTranslationKey.videoCall: 'Video call',
  AppTranslationKey.voiceCall: 'Voice call',
  AppTranslationKey.incomingVideoCall: 'Incoming video call',
  AppTranslationKey.incomingVoiceCall: 'Incoming voice call',
  AppTranslationKey.invalidCallData: 'Call data is incomplete',
  AppTranslationKey.waitUntilCallConnected: 'Wait until the call is connected',
  AppTranslationKey.videoRequestPending:
      'Video request is waiting for approval',
  AppTranslationKey.requestingVideoPermission: 'Requesting video permission...',
  AppTranslationKey.videoCallStarted: 'Video call started',
  AppTranslationKey.online: 'Online',
  AppTranslationKey.offline: 'Offline',
  AppTranslationKey.lastOnlineAt: 'Last online @time',
  AppTranslationKey.typing: 'typing...',
  AppTranslationKey.hiddenOnlineStatus: 'Online status is hidden',
  AppTranslationKey.call: 'Call',
  AppTranslationKey.reject: 'Decline',
  AppTranslationKey.accept: 'Accept',
  AppTranslationKey.end: 'End',
  AppTranslationKey.speaker: 'Speaker',
  AppTranslationKey.close: 'Close',
  AppTranslationKey.callInfo: 'Call info',
  AppTranslationKey.callHistory: 'Calls',
  AppTranslationKey.audio: 'Audio',
  AppTranslationKey.noCallHistory: 'No call history yet',
  AppTranslationKey.missedCall: 'Missed call',
  AppTranslationKey.ongoingCall: 'Ongoing call',
  AppTranslationKey.declined: 'Declined',
  AppTranslationKey.missed: 'Missed',
  AppTranslationKey.ongoing: 'Ongoing',
  AppTranslationKey.ended: 'Ended',
  AppTranslationKey.seconds: '@count seconds',
  AppTranslationKey.minutesSeconds: '@minutes minutes @seconds seconds',
  AppTranslationKey.fileOpenFailed: 'File cannot be opened',
  AppTranslationKey.incomingRequests: 'Incoming',
  AppTranslationKey.sentRequests: 'Sent',
  AppTranslationKey.friendRequests: 'Friend Requests',
  AppTranslationKey.noIncomingRequests: 'No incoming requests',
  AppTranslationKey.noSentRequests: 'No sent requests',
  AppTranslationKey.waitingApproval: 'Waiting for approval',
  AppTranslationKey.addFriend: 'Add Friend',
  AppTranslationKey.friendAdded: 'Friend added',
  AppTranslationKey.findFriendByUsername: 'Find friends by username',
  AppTranslationKey.usernameExample: 'example: nicola123',
  AppTranslationKey.login: 'Sign in',
  AppTranslationKey.welcomeBack: 'Welcome Back',
  AppTranslationKey.forgotPassword: 'Forgot Password?',
  AppTranslationKey.resetPassword: 'Reset Password',
  AppTranslationKey.forgotPasswordInstruction:
      'Enter your account username or email. If the account is found, we will send a password reset link to the registered email.',
  AppTranslationKey.usernameOrEmail: 'Username or Email',
  AppTranslationKey.enterUsernameOrEmail: 'Enter username or email',
  AppTranslationKey.sendResetLink: 'Send Reset Link',
  AppTranslationKey.resetLinkSentTitle: 'Check Your Email',
  AppTranslationKey.resetLinkSentMessage:
      'If the account is found, we have sent a password reset link to the registered email.',
  AppTranslationKey.backToLogin: 'Back to Sign In',
  AppTranslationKey.dontHaveAccount: 'Do not have an account? ',
  AppTranslationKey.register: 'Sign up',
  AppTranslationKey.welcome: 'Welcome',
  AppTranslationKey.registerSubtitle:
      'Create an account now so we can stay connected!!',
  AppTranslationKey.alreadyHaveAccount: 'Already have an account? ',
  AppTranslationKey.verifyNow: 'Verify Now',
  AppTranslationKey.verifyEmailToAccessFeatures:
      'Please verify your email to access all our features',
  AppTranslationKey.verifyEmail: 'Verify Email',
  AppTranslationKey.verifyEmailInstruction:
      'Open @email and click the verification link we sent',
  AppTranslationKey.newEmailVerifiedMessage:
      'Your new email has been verified. For account security, please sign in again with your username and password.',
  AppTranslationKey.relogin: 'Sign In Again',
  AppTranslationKey.name: 'Name',
  AppTranslationKey.username: 'Username',
  AppTranslationKey.email: 'Email',
  AppTranslationKey.enterName: 'Enter name',
  AppTranslationKey.enterUsername: 'Enter username',
  AppTranslationKey.enterEmail: 'Enter email',
  AppTranslationKey.emailVerificationRequired:
      'Please verify your email so you can access all features',
  AppTranslationKey.registrationSuccessTitle: 'Yay!! Registration Successful',
  AppTranslationKey.resendLink: 'Resend Link',
  AppTranslationKey.emailChangedTitle: 'Email Changed',
  AppTranslationKey.accountSettings: 'Account Settings',
  AppTranslationKey.changeEmail: 'Change Email',
  AppTranslationKey.changePassword: 'Change Password',
  AppTranslationKey.chooseOption: 'Choose Option',
  AppTranslationKey.chooseFromGallery: 'Choose from gallery',
  AppTranslationKey.takePhoto: 'Take photo',
  AppTranslationKey.removePhoto: 'Remove photo',
  AppTranslationKey.uploadingImage: 'Uploading image...',
  AppTranslationKey.language: 'Language',
  AppTranslationKey.languageChangedToId: 'Bahasa diubah ke Indonesia.',
  AppTranslationKey.languageChangedToEn: 'Language changed to English.',
  AppTranslationKey.indonesian: 'Indonesian',
  AppTranslationKey.english: 'English',
  AppTranslationKey.notifications: 'Notifications',
  AppTranslationKey.dark: 'Dark',
  AppTranslationKey.light: 'Light',
  AppTranslationKey.personalInformation: 'Personal Information',
  AppTranslationKey.success: 'Success',
  AppTranslationKey.profileUpdated: 'Profile updated successfully',
  AppTranslationKey.logout: 'Logout',
  AppTranslationKey.logoutConfirmationTitle: 'Logout from account?',
  AppTranslationKey.logoutConfirmationMessage:
      'You need to sign in again to use ChatKuy.',
  AppTranslationKey.yearsOld: '@age years old',
  AppTranslationKey.gender: 'Gender',
  AppTranslationKey.birthDate: 'Birth date',
  AppTranslationKey.phoneNumber: 'Phone number',
  AppTranslationKey.privacy: 'Privacy',
  AppTranslationKey.showEmail: 'Show email',
  AppTranslationKey.showEmailSubtitle:
      'Allow friends to see your email address',
  AppTranslationKey.showBirthDate: 'Show birth date',
  AppTranslationKey.showBirthDateSubtitle:
      'Allow friends to see your birth date',
  AppTranslationKey.showOnlineStatus: 'Show online status',
  AppTranslationKey.showOnlineStatusSubtitle:
      'Allow friends to see your online status. If disabled, you also cannot see your friends online status.',
  AppTranslationKey.saveChanges: 'Save Changes',
  AppTranslationKey.editProfile: 'Edit Profile',
  AppTranslationKey.chooseBirthDate: 'Choose birth date',
  AppTranslationKey.changePasswordAppbar: 'Change Password',
  AppTranslationKey.sendingVerificationLink: 'Sending verification link...',
  AppTranslationKey.currentPassword: 'Current Password',
  AppTranslationKey.password: 'Password',
  AppTranslationKey.confirmPassword: 'Confirm Password',
  AppTranslationKey.enterPassword: 'Enter password',
  AppTranslationKey.enterConfirmPassword: 'Enter password confirmation',
  AppTranslationKey.enterCurrentPassword: 'Enter current password',
  AppTranslationKey.mustLoginAgainAfterPasswordChange:
      'You need to sign in again after changing your password',
  AppTranslationKey.changeEmailAddress: 'Change Email Address',
  AppTranslationKey.newEmail: 'New Email',
  AppTranslationKey.enterNewEmail: 'Enter your new email',
  AppTranslationKey.confirm: 'Confirm',
  AppTranslationKey.failedChangeEmail: 'Failed to change email',
  AppTranslationKey.currentPasswordWrong: 'Current password is incorrect',
  AppTranslationKey.invalidUser: 'Invalid user',
  AppTranslationKey.failedChangePassword: 'Failed to change password',
  AppTranslationKey.emailVerifiedLoginAgain:
      'Email verified. Please sign in again.',
  AppTranslationKey.birthDateHidden: 'Hidden',
  AppTranslationKey.updateRequired: 'Update Required',
  AppTranslationKey.updateAvailable: 'Update Available',
  AppTranslationKey.updateRequiredMessage:
      'Your ChatKuy version is below the minimum supported version.',
  AppTranslationKey.updateAvailableMessage:
      'A newer version of ChatKuy is available. You can update now or continue for now.',
  AppTranslationKey.openAppTester: 'Open App Tester',
  AppTranslationKey.later: 'Later',
  AppTranslationKey.failedOpenAppTester: 'Failed to open App Tester',
  AppTranslationKey.invalidAppTesterUrl: 'App Tester URL is invalid',
  AppTranslationKey.tryAgainLater: 'Please try again in a moment',
  AppTranslationKey.yourVersion: 'Your version',
  AppTranslationKey.minimumAppVersion: 'Minimum app version',
  AppTranslationKey.recommendedAppVersion: 'Recommended app version',
  AppTranslationKey.minimumBuildNumber: 'Minimum build number',
  AppTranslationKey.recommendedBuildNumber: 'Recommended build number',
};
