using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Connector;
using System;
using System.Linq;

namespace NBABot
{
    [BotAuthentication]
    public class MessagesController : ApiController
    {
        /// <summary>
        /// POST: api/Messages
        /// Receive a message from a user and reply to it
        /// </summary>
        public async Task<HttpResponseMessage> Post([FromBody]Activity activity)
        {
            if (activity != null)
            {
                // one of these will have an interface and process it
                switch (activity.GetActivityType())
                {
                    case ActivityTypes.Message:
                        await Conversation.SendAsync(activity, () => new Dialogs.BasicLuisDialog());

                        break;
                    case ActivityTypes.ConversationUpdate:
                        var client = new ConnectorClient(new Uri(activity.ServiceUrl));
                        IConversationUpdateActivity update = activity;
                        if (update.MembersAdded.Any())
                        {
                            var reply = activity.CreateReply();
                            var newMembers = update.MembersAdded?.Where(t => t.Id != activity.Recipient.Id);
                            foreach (var newMember in newMembers)
                            {
                                reply.Text = "Welcome";
                                if (!string.IsNullOrEmpty(newMember.Name))
                                {
                                    reply.Text += $" {newMember.Name}";
                                }
                                reply.Text += "!";
                                await client.Conversations.ReplyToActivityAsync(reply);
                            }
                        }
                        break;
                    case ActivityTypes.ContactRelationUpdate:
                    case ActivityTypes.Typing:
                    case ActivityTypes.DeleteUserData:
                    case ActivityTypes.Ping:
                    default:
                        break;
                }
            }
            return Request.CreateResponse(HttpStatusCode.Accepted);

        }

    }
}