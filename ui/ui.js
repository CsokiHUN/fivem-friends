const app = Vue.createApp({
  data() {
    return {
      panelTitles: {
        pendings: 'Kérelmek',
        friends: 'Barátok',
      },

      visible: false,
      page: 'friends',
      targetID: '',

      friends: [],
      pendings: [],
    };
  },
  computed: {
    listData() {
      return this[this.page];
    },
  },
  methods: {
    formatDate: formatDate,

    changePage(page) {
      this.page = page;
    },

    close() {
      fetch(`https://${GetParentResourceName()}/close`);
    },

    async accept(row) {
      const response = await fetch(
        `https://${GetParentResourceName()}/acceptPending`,
        {
          method: 'POST',
          body: JSON.stringify({
            row,
          }),
        }
      );

      const { success, friends, pendings } = await response.json();

      if (success) {
        this.friends = friends;
        this.pendings = pendings;
      }
    },

    async del(row) {
      const response = await fetch(
        `https://${GetParentResourceName()}/delete`,
        {
          method: 'POST',
          body: JSON.stringify({
            row,
            page: this.page,
          }),
        }
      );

      const { success, pendings, friends } = await response.json();
      if (success) {
        if (this.page == 'pendings') {
          this.pendings = pendings;
        } else {
          this.friends = friends;
        }
      }
    },

    async sendNew() {
      const response = await fetch(
        `https://${GetParentResourceName()}/sendNew`,
        {
          method: 'POST',
          body: JSON.stringify({
            id: this.targetID,
          }),
        }
      );

      const { success, pendings } = await response.json();

      if (success) {
        this.targetID = '';
        this.pendings = pendings;
      }
    },
  },
  created() {
    window.addEventListener('message', (event) => {
      const { data } = event;

      if (data.visible != undefined) {
        this.visible = data.visible;
      }

      if (data.pendings != undefined) {
        this.pendings = data.pendings;
      }

      if (data.friends != undefined) {
        this.friends = data.friends;
      }
    });
  },
}).mount('#app');

function formatDate(timestamp) {
  const currentDatetime = new Date();
  currentDatetime.setTime(timestamp * 1000);

  const addLeadingZeros = (n) => {
    if (n <= 9) {
      return '0' + n;
    }
    return n;
  };

  return (
    currentDatetime.getFullYear() +
    '-' +
    addLeadingZeros(currentDatetime.getMonth() + 1) +
    '-' +
    addLeadingZeros(currentDatetime.getDate()) +
    ' ' +
    addLeadingZeros(currentDatetime.getHours()) +
    ':' +
    addLeadingZeros(currentDatetime.getMinutes()) +
    ':' +
    addLeadingZeros(currentDatetime.getSeconds())
  );
}
